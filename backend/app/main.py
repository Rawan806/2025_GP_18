import os
import json
import time
from io import BytesIO
from contextlib import asynccontextmanager
from typing import Optional, List, Dict, Any, Tuple

import numpy as np
import requests
from PIL import Image
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

import tensorflow as tf
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input

from sentence_transformers import SentenceTransformer

try:
    from .firebase_config import init_firestore
except ImportError:
    from firebase_config import init_firestore

# =========================================
# Paths
# =========================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACTS_DIR = os.path.join(BASE_DIR, "artifacts")
DYNAMIC_EMBEDDINGS_DIR = os.path.join(ARTIFACTS_DIR, "dynamic_embeddings")
DYNAMIC_TEXT_EMBEDDINGS_DIR = os.path.join(ARTIFACTS_DIR, "dynamic_text_embeddings")

EMBEDDINGS_PATH = os.path.join(ARTIFACTS_DIR, "embeddings.npy")
META_PATH = os.path.join(ARTIFACTS_DIR, "meta.json")
INDEX_INFO_PATH = os.path.join(ARTIFACTS_DIR, "index_info.json")
PREPROCESS_CONFIG_PATH = os.path.join(ARTIFACTS_DIR, "preprocess_config.json")

os.makedirs(DYNAMIC_EMBEDDINGS_DIR, exist_ok=True)
os.makedirs(DYNAMIC_TEXT_EMBEDDINGS_DIR, exist_ok=True)

# =========================================
# Model Config
# =========================================
IMG_SIZE = 224
POOLING = "avg"
MODEL_NAME = "MobileNetV3Small"
TEXT_MODEL_NAME = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

# =========================================
# Global in-memory artifacts
# =========================================
db = None
embeddings = None
feature_extractor = None
text_model = None

docid_to_index: Dict[str, int] = {}
index_info: Dict[str, Any] = {}
preprocess_config: Dict[str, Any] = {}

meta_items_list: List[Dict[str, Any]] = []
meta_items_map: Dict[str, Dict[str, Any]] = {}

STRONG_MATCH_THRESHOLD = 0.85
POTENTIAL_MATCH_THRESHOLD = 0.75
TEXT_STRONG_MATCH_THRESHOLD = 0.80
TEXT_POTENTIAL_MATCH_THRESHOLD = 0.65

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


def get_dynamic_text_embedding_path(doc_id: str) -> str:
    return os.path.join(DYNAMIC_TEXT_EMBEDDINGS_DIR, f"{normalize_doc_id(doc_id)}.npy")


def load_artifacts():
    global embeddings, docid_to_index, index_info, preprocess_config
    global meta_items_list, meta_items_map

    print("DEBUG: BASE_DIR =", BASE_DIR)
    print("DEBUG: ARTIFACTS_DIR =", ARTIFACTS_DIR)
    print("DEBUG: EMBEDDINGS_PATH exists =", os.path.exists(EMBEDDINGS_PATH), EMBEDDINGS_PATH)
    print("DEBUG: META_PATH exists =", os.path.exists(META_PATH), META_PATH)
    print("DEBUG: INDEX_INFO_PATH exists =", os.path.exists(INDEX_INFO_PATH), INDEX_INFO_PATH)
    print("DEBUG: PREPROCESS_CONFIG_PATH exists =", os.path.exists(PREPROCESS_CONFIG_PATH), PREPROCESS_CONFIG_PATH)

    if os.path.exists(EMBEDDINGS_PATH):
        embeddings = np.load(EMBEDDINGS_PATH)
        print("DEBUG: legacy image embeddings shape =", embeddings.shape)
    else:
        embeddings = None
        print("DEBUG: legacy image embeddings not found")

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
    print("DEBUG: dynamic image embeddings dir =", DYNAMIC_EMBEDDINGS_DIR)
    print("DEBUG: dynamic text embeddings dir =", DYNAMIC_TEXT_EMBEDDINGS_DIR)


def cosine_similarity_matrix(query_vec: np.ndarray, emb_matrix: np.ndarray) -> np.ndarray:
    return emb_matrix @ query_vec


def build_match_label(similarity: float) -> str:
    if similarity >= STRONG_MATCH_THRESHOLD:
        return "strong_match"
    elif similarity >= POTENTIAL_MATCH_THRESHOLD:
        return "potential_match"
    return "weak_match"


def build_text_match_label(similarity: float) -> str:
    if similarity >= TEXT_STRONG_MATCH_THRESHOLD:
        return "strong_match"
    elif similarity >= TEXT_POTENTIAL_MATCH_THRESHOLD:
        return "potential_match"
    return "weak_match"


def normalize_vector(vec: np.ndarray) -> np.ndarray:
    vec = vec.astype(np.float32).reshape(-1)
    norm = np.linalg.norm(vec)
    if norm == 0:
        return vec
    return vec / norm

# =========================================
# Text Matching Helpers
# =========================================
def _safe_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        value = value.strip()
        if value.lower() in ("null", "none", "-", ""):
            return ""
        return value
    if isinstance(value, (int, float, bool)):
        return str(value)
    return ""


def _flatten_dynamic_attributes(dynamic_attributes: Any) -> List[str]:
    parts: List[str] = []

    if not isinstance(dynamic_attributes, dict):
        return parts

    for key, value in dynamic_attributes.items():
        key_text = _safe_text(key)
        value_text = _safe_text(value)
        if key_text and value_text:
            parts.append(f"{key_text}: {value_text}")

    return parts


def build_searchable_text(item: Dict[str, Any]) -> str:
    """
    Builds one normalized text blob from both old and new Firestore schemas.
    This is the foundation for text-to-text matching.
    """
    priority_fields = [
        "title",
        "type",
        "category",
        "subtype",
        "color",
        "brand",
        "description",
        "specialMarks",
        "reportLocation",
        "foundLocation",
        "storageLocation",
        "documentType",
        "bagSize",
        "screenBroken",
        "coverColor",
        "hasCards",
        "hasCover",
        "coverDocumentColor",
        "jewelryMaterial",
        "hasStone",
        "watchType",
        "watchBandType",
        "watchScreenBroken",
        "watchShape",
        "watchFaceColor",
        "glassesType",
        "glassesFrameColor",
        "aiColor",
    ]

    parts: List[str] = []

    for field in priority_fields:
        value = _safe_text(item.get(field))
        if value:
            parts.append(f"{field}: {value}")

    ai_suggestions = item.get("aiSuggestions") or item.get("aiTypes")
    if isinstance(ai_suggestions, list):
        suggestions = [str(x).strip() for x in ai_suggestions if str(x).strip()]
        if suggestions:
            parts.append("ai suggestions: " + ", ".join(suggestions))

    parts.extend(_flatten_dynamic_attributes(item.get("dynamicAttributes")))

    searchable_text = " | ".join(parts)
    return " ".join(searchable_text.split()).strip()


def generate_text_embedding(searchable_text: str) -> Optional[np.ndarray]:
    if text_model is None:
        raise RuntimeError("Text model is not initialized")

    if not searchable_text.strip():
        return None

    emb = text_model.encode(searchable_text, normalize_embeddings=True)
    return normalize_vector(np.array(emb, dtype=np.float32))


def save_dynamic_text_embedding(doc_id: str, embedding: np.ndarray):
    path = get_dynamic_text_embedding_path(doc_id)
    np.save(path, normalize_vector(embedding))


def get_text_embedding_by_doc_id(doc_id: str) -> Optional[np.ndarray]:
    path = get_dynamic_text_embedding_path(doc_id)
    if not os.path.exists(path):
        return None

    try:
        emb = np.load(path)
        if emb.ndim > 1:
            emb = emb.reshape(-1)
        return normalize_vector(emb)
    except Exception as e:
        print(f"DEBUG: failed loading text embedding for {doc_id}: {e}")
        return None


def ensure_text_embedding_for_item(item: Dict[str, Any]) -> Tuple[Optional[np.ndarray], str]:
    doc_id = normalize_doc_id(item.get("docId"))
    if not doc_id:
        return None, ""

    existing = get_text_embedding_by_doc_id(doc_id)
    if existing is not None:
        return existing, build_searchable_text(item)

    searchable_text = build_searchable_text(item)
    if not searchable_text:
        return None, ""

    emb = generate_text_embedding(searchable_text)
    if emb is not None:
        save_dynamic_text_embedding(doc_id, emb)

    return emb, searchable_text


def item_has_image(item: Dict[str, Any]) -> bool:
    image_url = _safe_text(item.get("imageUrl") or item.get("imagePath"))
    return bool(image_url)

# =========================================
# Image Embedding Helpers
# =========================================
def get_embedding_by_doc_id(doc_id: str) -> Optional[np.ndarray]:
    normalized_doc_id = normalize_doc_id(doc_id)

    dynamic_path = get_dynamic_embedding_path(normalized_doc_id)
    if os.path.exists(dynamic_path):
        try:
            emb = np.load(dynamic_path)
            if emb.ndim > 1:
                emb = emb.reshape(-1)
            return normalize_vector(emb)
        except Exception as e:
            print(f"DEBUG: failed loading dynamic image embedding for {normalized_doc_id}: {e}")

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

    doc_ref = db.collection(normalized_collection).document(normalized_doc_id)
    doc = doc_ref.get()

    if doc.exists:
        data = doc.to_dict() or {}
        data["docId"] = doc.id
        data["collection"] = normalized_collection
        return data

    docs = (
        db.collection(normalized_collection)
        .where("docId", "==", normalized_doc_id)
        .limit(1)
        .stream()
    )

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


def infer_collection_by_doc_id(doc_id: str) -> str:
    normalized_doc_id = normalize_doc_id(doc_id)

    for collection in ["lostItems", "foundItems"]:
        doc = db.collection(collection).document(normalized_doc_id).get()
        if doc.exists:
            return collection

        docs = (
            db.collection(collection)
            .where("docId", "==", normalized_doc_id)
            .limit(1)
            .stream()
        )
        for _ in docs:
            return collection

    meta_item = get_item_from_meta(normalized_doc_id)
    if meta_item is not None:
        return normalize_collection_name(meta_item.get("collection"))

    raise HTTPException(status_code=404, detail="DocId not found in lostItems or foundItems")


def resolve_collection(optional_collection: Optional[str], doc_id: str) -> str:
    if optional_collection and optional_collection.strip():
        return normalize_collection_name(optional_collection)
    return infer_collection_by_doc_id(doc_id)


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

    firestore_candidates = fetch_candidates_from_firestore(
        target_collection=normalized_collection,
        exclude_doc_id=excluded,
    )

    for item in firestore_candidates:
        item_doc_id = normalize_doc_id(item.get("docId"))
        if excluded and item_doc_id == excluded:
            continue
        combined[item_doc_id] = item

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
    dynamic_image_count = len([f for f in os.listdir(DYNAMIC_EMBEDDINGS_DIR) if f.endswith(".npy")])
    dynamic_text_count = len([f for f in os.listdir(DYNAMIC_TEXT_EMBEDDINGS_DIR) if f.endswith(".npy")])

    return {
        "indexed_count": len(lost_docs) + len(found_docs),
        "lost_count": len(lost_docs),
        "found_count": len(found_docs),
        "index_id": index_info.get("index_id"),
        "index_version": index_info.get("index_version"),
        "last_index_update": index_info.get("built_at"),
        "model_name": index_info.get("model_name", MODEL_NAME),
        "text_model_name": TEXT_MODEL_NAME,
        "embedding_shape": None if embeddings is None else list(embeddings.shape),
        "mapped_docids_count": len(docid_to_index),
        "legacy_meta_count": len(meta_items_list),
        "dynamic_embeddings_count": dynamic_image_count,
        "dynamic_text_embeddings_count": dynamic_text_count,
    }


def download_image_bytes(image_url: str) -> bytes:
    response = requests.get(image_url, timeout=30)
    response.raise_for_status()
    return response.content


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


def update_index_status(collection: str, doc_id: str, status: str, error_message: Optional[str] = None):
    doc_ref = db.collection(collection).document(doc_id)

    payload = {
        "isIndexed": status == "ready",
        "indexStatus": status,
        "indexedAt": None if status != "ready" else time.strftime("%Y-%m-%d %H:%M:%S"),
    }

    if error_message:
        payload["indexError"] = error_message
    else:
        payload["indexError"] = ""

    doc_ref.update(payload)

# =========================================
# Pydantic Models
# =========================================
class SearchRequest(BaseModel):
    docId: str = Field(..., description="The query item document ID")
    collection: Optional[str] = Field(None, description="Optional. If omitted, backend will infer lostItems/foundItems.")
    top_k: int = Field(5, ge=1, le=50)
    matchMode: str = Field(
        "auto",
        description="Matching mode: auto, image, or text.",
    )


class IndexItemRequest(BaseModel):
    docId: str = Field(..., description="The item document ID")
    collection: Optional[str] = Field(None, description="Optional. If omitted, backend will infer lostItems/foundItems.")


class SearchResult(BaseModel):
    docId: str
    collection: str
    imageUrl: Optional[str] = None
    similarity: float
    match_label: str
    matchMode: str
    imageSimilarity: Optional[float] = None
    textSimilarity: Optional[float] = None
    finalScore: Optional[float] = None
    type: Optional[str] = None
    color: Optional[str] = None
    location: Optional[str] = None
    status: Optional[str] = None


class SearchResponse(BaseModel):
    query_docId: str
    query_collection: str
    searched_in: str
    top_k: int
    matchMode: str
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
    global db, feature_extractor, text_model

    db = init_firestore()
    load_artifacts()

    feature_extractor = MobileNetV3Small(
        include_top=False,
        weights="imagenet",
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        pooling=POOLING,
    )
    print("DEBUG: image feature extractor ready")

    text_model = SentenceTransformer(TEXT_MODEL_NAME)
    print("DEBUG: text embedding model ready")

    yield

# =========================================
# App
# =========================================
app = FastAPI(
    title="Wadiah Backend API",
    version="2.5.0-text-matching",
    lifespan=lifespan,
)

# =========================================
# Routes
# =========================================
@app.get("/")
def root():
    return {
        "message": "Wadiah API is running",
        "data_source": "Firestore + legacy meta + local image embeddings + dynamic image/text indexing",
        "collection_mode": "collection is optional; backend can infer it from docId",
        "text_matching": True,
        "image_matching": True,
    }


@app.get("/health")
def health_check():
    firestore_ok = db is not None
    embeddings_ok = embeddings is not None
    mapping_ok = len(docid_to_index) > 0
    image_model_ok = feature_extractor is not None
    text_model_ok = text_model is not None

    return {
        "status": "ok" if firestore_ok and image_model_ok and text_model_ok else "partial",
        "firestore_connected": firestore_ok,
        "legacy_image_embeddings_loaded": embeddings_ok,
        "docid_mapping_loaded": mapping_ok,
        "legacy_meta_loaded": len(meta_items_list) > 0,
        "image_model_loaded": image_model_ok,
        "text_model_loaded": text_model_ok,
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

    if item is None:
        item = get_item_from_meta(doc_id)
        if item is not None and item.get("collection") != normalized_collection:
            item = None

    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    item["has_image_embedding"] = get_embedding_by_doc_id(item["docId"]) is not None
    item["has_text_embedding"] = get_text_embedding_by_doc_id(item["docId"]) is not None
    item["searchableText"] = build_searchable_text(item)
    return item


@app.get("/item/{doc_id}")
def get_item_auto(doc_id: str):
    collection = infer_collection_by_doc_id(doc_id)
    item = get_item_from_firestore(collection, doc_id)

    if item is None:
        item = get_item_from_meta(doc_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    item["collection"] = collection
    item["has_image_embedding"] = get_embedding_by_doc_id(item["docId"]) is not None
    item["has_text_embedding"] = get_text_embedding_by_doc_id(item["docId"]) is not None
    item["searchableText"] = build_searchable_text(item)
    return item


@app.post("/index-item")
def index_item(payload: IndexItemRequest):
    collection = resolve_collection(payload.collection, payload.docId)
    item = get_item_from_firestore(collection, payload.docId)

    if item is None:
        raise HTTPException(
            status_code=404,
            detail="Item not found in Firestore. Legacy meta items cannot be re-indexed without Firestore data.",
        )

    image_url = _safe_text(item.get("imageUrl") or item.get("imagePath"))
    searchable_text = build_searchable_text(item)

    image_embedding_saved = False
    text_embedding_saved = False
    errors: List[str] = []

    try:
        update_index_status(collection, payload.docId, "processing")

        # 1) Text embedding: always try if form fields exist.
        if searchable_text:
            text_embedding = generate_text_embedding(searchable_text)
            if text_embedding is not None:
                save_dynamic_text_embedding(payload.docId, text_embedding)
                text_embedding_saved = True
        else:
            errors.append("Missing searchable text fields")

        # 2) Image embedding: only if image exists.
        if image_url:
            try:
                image_bytes = download_image_bytes(image_url)
                image_embedding = generate_embedding_from_image_bytes(image_bytes)

                if image_embedding is None or not isinstance(image_embedding, np.ndarray):
                    raise ValueError("Image embedding generation failed")

                save_dynamic_embedding(payload.docId, image_embedding)
                image_embedding_saved = True
            except Exception as image_error:
                errors.append(f"Image indexing failed: {image_error}")
        else:
            errors.append("No imageUrl/imagePath; skipped image embedding")

        if not image_embedding_saved and not text_embedding_saved:
            update_index_status(collection, payload.docId, "failed", "; ".join(errors))
            raise HTTPException(status_code=400, detail="Indexing failed: " + "; ".join(errors))

        update_index_status(collection, payload.docId, "ready")

        db.collection(collection).document(payload.docId).update({
            "hasImageEmbedding": image_embedding_saved,
            "hasTextEmbedding": text_embedding_saved,
            "searchableText": searchable_text,
            "indexWarnings": errors,
            "updatedAt": time.strftime("%Y-%m-%d %H:%M:%S"),
        })

        return {
            "status": "success",
            "docId": payload.docId,
            "collection": collection,
            "image_embedding_saved": image_embedding_saved,
            "text_embedding_saved": text_embedding_saved,
            "searchable_text_length": len(searchable_text),
            "warnings": errors,
        }

    except HTTPException:
        raise
    except Exception as e:
        update_index_status(collection, payload.docId, "failed", str(e))
        raise HTTPException(status_code=500, detail=f"Indexing failed: {str(e)}")


def _empty_search_response(
    payload: SearchRequest,
    query_collection: str,
    target_collection: str,
    match_mode: str,
    start_time: float,
    candidate_pool_size: int = 0,
    skipped_count: int = 0,
) -> Dict[str, Any]:
    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    return {
        "query_docId": payload.docId,
        "query_collection": query_collection,
        "searched_in": target_collection,
        "top_k": payload.top_k,
        "matchMode": match_mode,
        "potential_matches_count": 0,
        "candidate_pool_size": candidate_pool_size,
        "skipped_candidates_without_embedding": skipped_count,
        "search_time_ms": elapsed_ms,
        "results": [],
    }


def resolve_requested_match_mode(match_mode: Optional[str]) -> str:
    value = (match_mode or "auto").strip().lower()

    if value in {"", "auto"}:
        return "auto"
    if value in {"image", "item", "image_similarity", "item_similarity"}:
        return "image"
    if value in {"text", "texts", "text_similarity", "textsimilarity"}:
        return "text"

    raise HTTPException(status_code=400, detail="Invalid matchMode. Use auto, image, or text.")


@app.post("/search", response_model=SearchResponse)
def search_similar_items(payload: SearchRequest):
    start_time = time.perf_counter()
    requested_match_mode = resolve_requested_match_mode(payload.matchMode)

    query_collection = resolve_collection(payload.collection, payload.docId)
    target_collection = get_opposite_collection(query_collection)

    query_item = get_item_from_firestore(query_collection, payload.docId)

    if query_item is None:
        query_item = get_item_from_meta(payload.docId)
        if query_item is not None and query_item.get("collection") != query_collection:
            query_item = None

    if query_item is None:
        return _empty_search_response(payload, query_collection, target_collection, "none", start_time)

    query_image_embedding = get_embedding_by_doc_id(query_item["docId"])
    query_text_embedding, _ = ensure_text_embedding_for_item(query_item)

    # Decision rule:
    # - auto: prefer image, otherwise text.
    # - image/text: enforce the requested mode if the query supports it.
    if requested_match_mode == "image":
        if query_image_embedding is None:
            raise HTTPException(
                status_code=400,
                detail="Requested image matching, but the query item has no image embedding.",
            )
        match_mode = "image"
        query_embedding = query_image_embedding
    elif requested_match_mode == "text":
        if query_text_embedding is None:
            raise HTTPException(
                status_code=400,
                detail="Requested text matching, but the query item has no searchable text embedding.",
            )
        match_mode = "text"
        query_embedding = query_text_embedding
    elif query_image_embedding is not None:
        match_mode = "image"
        query_embedding = query_image_embedding
    elif query_text_embedding is not None:
        match_mode = "text"
        query_embedding = query_text_embedding
    else:
        return _empty_search_response(payload, query_collection, target_collection, "none", start_time)

    candidates = fetch_candidates_combined(
        target_collection=target_collection,
        exclude_doc_id=query_item["docId"],
    )

    candidate_embeddings = []
    candidate_items = []
    skipped_count = 0

    for item in candidates:
        if match_mode == "image":
            emb = get_embedding_by_doc_id(item["docId"])
        else:
            emb, _ = ensure_text_embedding_for_item(item)

        if emb is None:
            skipped_count += 1
            continue

        candidate_embeddings.append(emb)
        candidate_items.append(item)

    if not candidate_items:
        return _empty_search_response(
            payload,
            query_collection,
            target_collection,
            match_mode,
            start_time,
            candidate_pool_size=len(candidates),
            skipped_count=skipped_count,
        )

    candidate_embeddings_matrix = np.stack(candidate_embeddings, axis=0)
    scores = cosine_similarity_matrix(query_embedding, candidate_embeddings_matrix)
    top_indices = np.argsort(-scores)[:payload.top_k]

    results = []

    for idx in top_indices:
        item = candidate_items[int(idx)]
        sim = float(scores[int(idx)])
        label = build_match_label(sim) if match_mode == "image" else build_text_match_label(sim)

        results.append({
            "docId": item.get("docId"),
            "collection": item.get("collection"),
            "imageUrl": item.get("imageUrl") or item.get("imagePath"),
            "similarity": sim,
            "match_label": label,
            "matchMode": match_mode,
            "imageSimilarity": sim if match_mode == "image" else None,
            "textSimilarity": sim if match_mode == "text" else None,
            "finalScore": sim,
            "type": item.get("type"),
            "color": item.get("color"),
            "location": item.get("location") or item.get("foundLocation") or item.get("reportLocation"),
            "status": item.get("status"),
        })

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    sorted_scores_desc = np.sort(scores)[::-1]
    threshold = POTENTIAL_MATCH_THRESHOLD if match_mode == "image" else TEXT_POTENTIAL_MATCH_THRESHOLD

    return {
        "query_docId": query_item["docId"],
        "query_collection": query_collection,
        "searched_in": target_collection,
        "top_k": payload.top_k,
        "matchMode": match_mode,
        "top_score": float(sorted_scores_desc[0]),
        "avg_top5_score": float(np.mean(sorted_scores_desc[:min(5, len(sorted_scores_desc))])),
        "potential_matches_count": int(np.sum(scores >= threshold)),
        "candidate_pool_size": len(candidates),
        "skipped_candidates_without_embedding": skipped_count,
        "search_time_ms": elapsed_ms,
        "index_version": index_info.get("index_version"),
        "index_id": index_info.get("index_id"),
        "results": results,
    }


@app.get("/debug/meta-check")
def debug_meta_check():
    dynamic_image_files = [f for f in os.listdir(DYNAMIC_EMBEDDINGS_DIR) if f.endswith(".npy")]
    dynamic_text_files = [f for f in os.listdir(DYNAMIC_TEXT_EMBEDDINGS_DIR) if f.endswith(".npy")]

    return {
        "FIRESTORE_COLLECTIONS_EXPECTED": ["lostItems", "foundItems"],
        "MAPPED_DOCIDS_COUNT": len(docid_to_index),
        "LEGACY_META_COUNT": len(meta_items_list),
        "FIRESTORE_CONNECTED": db is not None,
        "IMAGE_MODEL_LOADED": feature_extractor is not None,
        "TEXT_MODEL_LOADED": text_model is not None,
        "DYNAMIC_IMAGE_EMBEDDINGS_COUNT": len(dynamic_image_files),
        "DYNAMIC_TEXT_EMBEDDINGS_COUNT": len(dynamic_text_files),
        "DYNAMIC_IMAGE_SAMPLE": dynamic_image_files[:10],
        "DYNAMIC_TEXT_SAMPLE": dynamic_text_files[:10],
    }
