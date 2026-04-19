import os
import json
import time
from io import BytesIO
from contextlib import asynccontextmanager
from typing import Optional, List, Dict, Any

import numpy as np
import requests
from PIL import Image
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

import tensorflow as tf
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input

from .firebase_config import init_firestore

# =========================================
# Paths
# =========================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACTS_DIR = os.path.join(BASE_DIR, "artifacts")
DYNAMIC_EMBEDDINGS_DIR = os.path.join(ARTIFACTS_DIR, "dynamic_embeddings")

EMBEDDINGS_PATH = os.path.join(ARTIFACTS_DIR, "embeddings.npy")
META_PATH = os.path.join(ARTIFACTS_DIR, "meta.json")
INDEX_INFO_PATH = os.path.join(ARTIFACTS_DIR, "index_info.json")
PREPROCESS_CONFIG_PATH = os.path.join(ARTIFACTS_DIR, "preprocess_config.json")

os.makedirs(DYNAMIC_EMBEDDINGS_DIR, exist_ok=True)

# =========================================
# Model Config
# =========================================
IMG_SIZE = 224
POOLING = "avg"
MODEL_NAME = "MobileNetV3Small"

# =========================================
# Global in-memory artifacts
# =========================================
db = None
embeddings = None
feature_extractor = None

docid_to_index: Dict[str, int] = {}
index_info: Dict[str, Any] = {}
preprocess_config: Dict[str, Any] = {}

# legacy meta support
meta_items_list: List[Dict[str, Any]] = []
meta_items_map: Dict[str, Dict[str, Any]] = {}

STRONG_MATCH_THRESHOLD = 0.85
POTENTIAL_MATCH_THRESHOLD = 0.75

COLLECTION_MAP = {
    "lostItems": "lostItems",
    "foundItems": "foundItems"
}

# =========================================
# Helpers
# =========================================
def load_json_file(path: str, default):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return default


def normalize_doc_id(doc_id: Any) -> str:
    return str(doc_id).strip()


def normalize_collection_name(collection: str) -> str:
    if not collection:
        raise ValueError("Collection is required")

    value = collection.strip().lower()

    if value in ("lost", "lostitems", "lost_items"):
        return "lostItems"
    if value in ("found", "founditems", "found_items"):
        return "foundItems"

    raise ValueError("Invalid collection. Use 'lostItems' or 'foundItems'.")


def get_opposite_collection(collection: str) -> str:
    normalized = normalize_collection_name(collection)
    return "foundItems" if normalized == "lostItems" else "lostItems"


def get_dynamic_embedding_path(doc_id: str) -> str:
    return os.path.join(DYNAMIC_EMBEDDINGS_DIR, f"{normalize_doc_id(doc_id)}.npy")


def load_artifacts():
    global embeddings, docid_to_index, index_info, preprocess_config, meta_items_list, meta_items_map

    print("DEBUG: BASE_DIR =", BASE_DIR)
    print("DEBUG: ARTIFACTS_DIR =", ARTIFACTS_DIR)
    print("DEBUG: EMBEDDINGS_PATH exists =", os.path.exists(EMBEDDINGS_PATH), EMBEDDINGS_PATH)
    print("DEBUG: META_PATH exists =", os.path.exists(META_PATH), META_PATH)
    print("DEBUG: INDEX_INFO_PATH exists =", os.path.exists(INDEX_INFO_PATH), INDEX_INFO_PATH)
    print("DEBUG: PREPROCESS_CONFIG_PATH exists =", os.path.exists(PREPROCESS_CONFIG_PATH), PREPROCESS_CONFIG_PATH)

    if os.path.exists(EMBEDDINGS_PATH):
        embeddings = np.load(EMBEDDINGS_PATH)
        print("DEBUG: embeddings shape =", embeddings.shape)
    else:
        embeddings = None
        print("DEBUG: embeddings not found")

    raw_meta = load_json_file(META_PATH, [])
    meta_items_list = []

    for item in raw_meta:
        normalized_item = dict(item)

        try:
            normalized_item["collection"] = normalize_collection_name(item.get("collection", ""))
        except Exception:
            continue

        normalized_item["docId"] = normalize_doc_id(item.get("docId"))
        meta_items_list.append(normalized_item)

    docid_to_index = {
        normalize_doc_id(item.get("docId")): i
        for i, item in enumerate(meta_items_list)
        if item.get("docId") is not None
    }

    meta_items_map = {
        normalize_doc_id(item["docId"]): item
        for item in meta_items_list
        if item.get("docId")
    }

    index_info = load_json_file(INDEX_INFO_PATH, {})
    preprocess_config = load_json_file(PREPROCESS_CONFIG_PATH, {})

    print("DEBUG: loaded docid_to_index size =", len(docid_to_index))
    print("DEBUG: loaded meta_items_map size =", len(meta_items_map))
    print("DEBUG: dynamic_embeddings_dir =", DYNAMIC_EMBEDDINGS_DIR)


def cosine_similarity_matrix(query_vec: np.ndarray, emb_matrix: np.ndarray) -> np.ndarray:
    return emb_matrix @ query_vec


def build_match_label(similarity: float) -> str:
    if similarity >= STRONG_MATCH_THRESHOLD:
        return "strong_match"
    elif similarity >= POTENTIAL_MATCH_THRESHOLD:
        return "potential_match"
    return "weak_match"


def normalize_vector(vec: np.ndarray) -> np.ndarray:
    vec = vec.astype(np.float32).reshape(-1)
    norm = np.linalg.norm(vec)
    if norm == 0:
        return vec
    return vec / norm


def get_embedding_by_doc_id(doc_id: str) -> Optional[np.ndarray]:
    normalized_doc_id = normalize_doc_id(doc_id)

    # 1) Dynamic embedding first
    dynamic_path = get_dynamic_embedding_path(normalized_doc_id)
    if os.path.exists(dynamic_path):
        try:
            emb = np.load(dynamic_path)
            if emb.ndim > 1:
                emb = emb.reshape(-1)
            return normalize_vector(emb)
        except Exception as e:
            print(f"DEBUG: failed loading dynamic embedding for {normalized_doc_id}: {e}")

    # 2) Fallback to static embedding
    if embeddings is None:
        return None

    idx = docid_to_index.get(normalized_doc_id)
    if idx is None or idx < 0 or idx >= len(embeddings):
        return None

    emb = embeddings[idx]
    if emb.ndim > 1:
        emb = emb.reshape(-1)

    return normalize_vector(emb)


def save_dynamic_embedding(doc_id: str, embedding: np.ndarray):
    path = get_dynamic_embedding_path(doc_id)
    np.save(path, normalize_vector(embedding))


def get_item_from_firestore(collection: str, doc_id: str) -> Optional[Dict[str, Any]]:
    normalized_collection = normalize_collection_name(collection)
    normalized_doc_id = normalize_doc_id(doc_id)

    # direct by document id
    doc_ref = db.collection(normalized_collection).document(normalized_doc_id)
    doc = doc_ref.get()

    if doc.exists:
        data = doc.to_dict() or {}
        data["docId"] = doc.id
        data["collection"] = normalized_collection
        return data

    # fallback by field docId
    docs = db.collection(normalized_collection).where("docId", "==", normalized_doc_id).stream()
    for matched_doc in docs:
        data = matched_doc.to_dict() or {}
        data["docId"] = normalize_doc_id(data.get("docId", matched_doc.id))
        data["collection"] = normalized_collection
        return data

    return None


def get_item_from_meta(doc_id: str) -> Optional[Dict[str, Any]]:
    normalized_doc_id = normalize_doc_id(doc_id)
    item = meta_items_map.get(normalized_doc_id)

    if item is None:
        return None

    normalized_item = dict(item)
    normalized_item["docId"] = normalized_doc_id
    normalized_item["collection"] = normalize_collection_name(item.get("collection", ""))
    return normalized_item


def fetch_candidates_from_firestore(target_collection: str, exclude_doc_id: Optional[str] = None) -> List[Dict[str, Any]]:
    normalized_collection = normalize_collection_name(target_collection)
    docs = db.collection(normalized_collection).stream()
    candidates = []
    excluded = normalize_doc_id(exclude_doc_id) if exclude_doc_id else None

    for doc in docs:
        item = doc.to_dict() or {}
        item_doc_id = normalize_doc_id(item.get("docId", doc.id))

        if excluded and item_doc_id == excluded:
            continue

        item["docId"] = item_doc_id
        item["collection"] = normalized_collection
        candidates.append(item)

    return candidates


def fetch_candidates_combined(target_collection: str, exclude_doc_id: Optional[str] = None) -> List[Dict[str, Any]]:
    normalized_collection = normalize_collection_name(target_collection)
    excluded = normalize_doc_id(exclude_doc_id) if exclude_doc_id else None

    combined: Dict[str, Dict[str, Any]] = {}

    # 1) Firestore candidates
    firestore_candidates = fetch_candidates_from_firestore(
        target_collection=normalized_collection,
        exclude_doc_id=excluded
    )

    for item in firestore_candidates:
        item_doc_id = normalize_doc_id(item.get("docId"))
        if excluded and item_doc_id == excluded:
            continue
        combined[item_doc_id] = item

    # 2) Legacy meta candidates
    for item in meta_items_list:
        item_doc_id = normalize_doc_id(item.get("docId"))
        item_collection = normalize_collection_name(item.get("collection", ""))

        if item_collection != normalized_collection:
            continue

        if excluded and item_doc_id == excluded:
            continue

        if item_doc_id not in combined:
            combined[item_doc_id] = dict(item)

    return list(combined.values())


def build_stats_from_firestore() -> Dict[str, Any]:
    lost_docs = list(db.collection("lostItems").stream())
    found_docs = list(db.collection("foundItems").stream())
    dynamic_count = len([f for f in os.listdir(DYNAMIC_EMBEDDINGS_DIR) if f.endswith(".npy")])

    return {
        "indexed_count": len(lost_docs) + len(found_docs),
        "lost_count": len(lost_docs),
        "found_count": len(found_docs),
        "index_id": index_info.get("index_id"),
        "index_version": index_info.get("index_version"),
        "last_index_update": index_info.get("built_at"),
        "model_name": index_info.get("model_name", MODEL_NAME),
        "embedding_shape": None if embeddings is None else list(embeddings.shape),
        "mapped_docids_count": len(docid_to_index),
        "legacy_meta_count": len(meta_items_list),
        "dynamic_embeddings_count": dynamic_count,
    }


def download_image_bytes(image_url: str) -> bytes:
    response = requests.get(image_url, timeout=30)
    response.raise_for_status()
    return response.content


# =========================================
# Real Model Helpers
# =========================================
def preprocess_pil_image(img: Image.Image) -> np.ndarray:
    img = img.resize((IMG_SIZE, IMG_SIZE))
    arr = np.array(img).astype("float32")
    arr = preprocess_input(arr)
    return arr


def extract_embedding_from_pil(img: Image.Image) -> np.ndarray:
    if feature_extractor is None:
        raise RuntimeError("Feature extractor is not initialized")

    x = preprocess_pil_image(img)
    x = np.expand_dims(x, axis=0)

    emb = feature_extractor.predict(x, verbose=0)[0]
    emb = emb.astype("float32")
    emb = emb / (np.linalg.norm(emb) + 1e-10)
    return emb


def generate_embedding_from_image_bytes(image_bytes: bytes) -> np.ndarray:
    img = Image.open(BytesIO(image_bytes)).convert("RGB")
    return extract_embedding_from_pil(img)


def update_index_status(
        collection: str,
        doc_id: str,
        status: str,
        error_message: Optional[str] = None
):
    doc_ref = db.collection(collection).document(doc_id)
    payload = {
        "isIndexed": status == "ready",
        "indexStatus": status,
        "indexedAt": None if status != "ready" else time.strftime("%Y-%m-%d %H:%M:%S"),
    }
    if error_message:
        payload["indexError"] = error_message
    doc_ref.update(payload)


# =========================================
# Pydantic Models
# =========================================
class SearchRequest(BaseModel):
    docId: str = Field(..., description="The query item document ID")
    collection: str = Field(..., description="Either 'lostItems' or 'foundItems'")
    top_k: int = Field(5, ge=1, le=50)


class IndexItemRequest(BaseModel):
    docId: str = Field(..., description="The item document ID")
    collection: str = Field(..., description="Either 'lostItems' or 'foundItems'")


class SearchResult(BaseModel):
    docId: str
    collection: str
    imageUrl: Optional[str] = None
    similarity: float
    match_label: str
    type: Optional[str] = None
    color: Optional[str] = None
    location: Optional[str] = None
    status: Optional[str] = None


class SearchResponse(BaseModel):
    query_docId: str
    query_collection: str
    searched_in: str
    top_k: int
    top_score: Optional[float] = None
    avg_top5_score: Optional[float] = None
    potential_matches_count: int
    candidate_pool_size: int
    skipped_candidates_without_embedding: int
    search_time_ms: float
    index_version: Optional[str] = None
    index_id: Optional[str] = None
    results: List[SearchResult]


# =========================================
# App lifespan
# =========================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    global db, feature_extractor

    db = init_firestore()
    load_artifacts()

    feature_extractor = MobileNetV3Small(
        include_top=False,
        weights="imagenet",
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        pooling=POOLING
    )

    print("DEBUG: feature extractor ready")

    yield


# =========================================
# App
# =========================================
app = FastAPI(
    title="Wadiah Backend API",
    version="2.3.1",
    lifespan=lifespan
)


# =========================================
# Routes
# =========================================
@app.get("/")
def root():
    return {
        "message": "Wadiah API is running",
        "data_source": "Firestore + legacy meta + local embeddings + dynamic indexing"
    }


@app.get("/health")
def health_check():
    firestore_ok = db is not None
    embeddings_ok = embeddings is not None
    mapping_ok = len(docid_to_index) > 0
    model_ok = feature_extractor is not None

    return {
        "status": "ok" if firestore_ok and model_ok else "partial",
        "firestore_connected": firestore_ok,
        "embeddings_loaded": embeddings_ok,
        "docid_mapping_loaded": mapping_ok,
        "legacy_meta_loaded": len(meta_items_list) > 0,
        "model_loaded": model_ok,
    }


@app.get("/stats")
def get_stats():
    return build_stats_from_firestore()


@app.get("/item/{collection}/{doc_id}")
def get_item(collection: str, doc_id: str):
    try:
        normalized_collection = normalize_collection_name(collection)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    item = get_item_from_firestore(normalized_collection, doc_id)

    # fallback to legacy meta
    if item is None:
        item = get_item_from_meta(doc_id)
        if item is not None and item.get("collection") != normalized_collection:
            item = None

    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    item["has_embedding"] = get_embedding_by_doc_id(item["docId"]) is not None
    return item


@app.post("/index-item")
def index_item(payload: IndexItemRequest):
    try:
        collection = normalize_collection_name(payload.collection)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    item = get_item_from_firestore(collection, payload.docId)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    image_url = item.get("imageUrl") or item.get("imagePath")
    if not image_url:
        update_index_status(collection, payload.docId, "failed", "Missing imageUrl/imagePath")
        raise HTTPException(status_code=400, detail="Item has no imageUrl or imagePath")

    try:
        update_index_status(collection, payload.docId, "processing")

        image_bytes = download_image_bytes(image_url)
        embedding = generate_embedding_from_image_bytes(image_bytes)

        if embedding is None or not isinstance(embedding, np.ndarray):
            raise ValueError("Embedding generation failed")

        save_dynamic_embedding(payload.docId, embedding)
        update_index_status(collection, payload.docId, "ready")

        return {
            "status": "success",
            "docId": payload.docId,
            "collection": collection,
            "embedding_saved": True
        }

    except Exception as e:
        update_index_status(collection, payload.docId, "failed", str(e))
        raise HTTPException(status_code=500, detail=f"Indexing failed: {str(e)}")


@app.post("/search", response_model=SearchResponse)
def search_similar_items(payload: SearchRequest):
    start_time = time.perf_counter()

    try:
        query_collection = normalize_collection_name(payload.collection)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    target_collection = get_opposite_collection(query_collection)

    query_item = get_item_from_firestore(query_collection, payload.docId)

    # fallback to legacy meta
    if query_item is None:
        query_item = get_item_from_meta(payload.docId)
        if query_item is not None and query_item.get("collection") != query_collection:
            query_item = None

    if query_item is None:
        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
        return {
            "query_docId": payload.docId,
            "query_collection": query_collection,
            "searched_in": target_collection,
            "top_k": payload.top_k,
            "potential_matches_count": 0,
            "candidate_pool_size": 0,
            "skipped_candidates_without_embedding": 0,
            "search_time_ms": elapsed_ms,
            "results": []
        }

    query_embedding = get_embedding_by_doc_id(query_item["docId"])
    if query_embedding is None:
        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
        return {
            "query_docId": query_item["docId"],
            "query_collection": query_collection,
            "searched_in": target_collection,
            "top_k": payload.top_k,
            "potential_matches_count": 0,
            "candidate_pool_size": 0,
            "skipped_candidates_without_embedding": 0,
            "search_time_ms": elapsed_ms,
            "results": []
        }

    candidates = fetch_candidates_combined(
        target_collection=target_collection,
        exclude_doc_id=query_item["docId"]
    )

    candidate_embeddings = []
    candidate_items = []
    skipped_count = 0

    for item in candidates:
        emb = get_embedding_by_doc_id(item["docId"])
        if emb is None:
            skipped_count += 1
            continue
        candidate_embeddings.append(emb)
        candidate_items.append(item)

    if not candidate_items:
        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
        return {
            "query_docId": query_item["docId"],
            "query_collection": query_collection,
            "searched_in": target_collection,
            "top_k": payload.top_k,
            "potential_matches_count": 0,
            "candidate_pool_size": len(candidates),
            "skipped_candidates_without_embedding": skipped_count,
            "search_time_ms": elapsed_ms,
            "results": []
        }

    candidate_embeddings_matrix = np.stack(candidate_embeddings, axis=0)
    scores = cosine_similarity_matrix(query_embedding, candidate_embeddings_matrix)

    top_indices = np.argsort(-scores)[:payload.top_k]

    results = []
    for idx in top_indices:
        item = candidate_items[int(idx)]
        sim = float(scores[int(idx)])

        results.append({
            "docId": item.get("docId"),
            "collection": item.get("collection"),
            "imageUrl": item.get("imageUrl") or item.get("imagePath"),
            "similarity": sim,
            "match_label": build_match_label(sim),
            "type": item.get("type"),
            "color": item.get("color"),
            "location": item.get("location") or item.get("foundLocation") or item.get("reportLocation"),
            "status": item.get("status")
        })

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    sorted_scores_desc = np.sort(scores)[::-1]

    return {
        "query_docId": query_item["docId"],
        "query_collection": query_collection,
        "searched_in": target_collection,
        "top_k": payload.top_k,
        "top_score": float(sorted_scores_desc[0]),
        "avg_top5_score": float(np.mean(sorted_scores_desc[:min(5, len(sorted_scores_desc))])),
        "potential_matches_count": int(np.sum(scores >= POTENTIAL_MATCH_THRESHOLD)),
        "candidate_pool_size": len(candidates),
        "skipped_candidates_without_embedding": skipped_count,
        "search_time_ms": elapsed_ms,
        "index_version": index_info.get("index_version"),
        "index_id": index_info.get("index_id"),
        "results": results
    }


@app.get("/debug/meta-check")
def debug_meta_check():
    dynamic_files = [f for f in os.listdir(DYNAMIC_EMBEDDINGS_DIR) if f.endswith(".npy")]
    return {
        "FIRESTORE_COLLECTIONS_EXPECTED": ["lostItems", "foundItems"],
        "MAPPED_DOCIDS_COUNT": len(docid_to_index),
        "LEGACY_META_COUNT": len(meta_items_list),
        "FIRESTORE_CONNECTED": db is not None,
        "MODEL_LOADED": feature_extractor is not None,
        "DYNAMIC_EMBEDDINGS_COUNT": len(dynamic_files),
        "DYNAMIC_SAMPLE": dynamic_files[:10],
    }