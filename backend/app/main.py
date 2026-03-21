import os
import json
import time
import numpy as np

from typing import Optional, List
from fastapi import FastAPI
from pydantic import BaseModel

# =========================================
# Paths
# =========================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACTS_DIR = os.path.join(BASE_DIR, "artifacts")

EMBEDDINGS_PATH = os.path.join(ARTIFACTS_DIR, "embeddings.npy")
META_PATH = os.path.join(ARTIFACTS_DIR, "meta.json")
INDEX_INFO_PATH = os.path.join(ARTIFACTS_DIR, "index_info.json")
PREPROCESS_CONFIG_PATH = os.path.join(ARTIFACTS_DIR, "preprocess_config.json")

# =========================================
# App
# =========================================
app = FastAPI(
    title="Wadiah Backend API",
    version="1.0.0"
)

# =========================================
# Global in-memory artifacts
# =========================================
embeddings = None
meta = []
index_info = {}
preprocess_config = {}

STRONG_MATCH_THRESHOLD = 0.85
POTENTIAL_MATCH_THRESHOLD = 0.75


# =========================================
# Helpers
# =========================================
def load_json_file(path: str, default):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return default


def load_artifacts():
    global embeddings, meta, index_info, preprocess_config

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

    meta = load_json_file(META_PATH, [])
    index_info = load_json_file(INDEX_INFO_PATH, {})
    preprocess_config = load_json_file(PREPROCESS_CONFIG_PATH, {})

    print("DEBUG: loaded meta size =", len(meta))
    if len(meta) > 0:
        print("DEBUG: first 3 docIds =", [str(item.get("docId")).strip() for item in meta[:3]])


def cosine_similarity_matrix(query_vec: np.ndarray, emb_matrix: np.ndarray) -> np.ndarray:
    return emb_matrix @ query_vec


def get_query_by_doc_id(doc_id: str):
    if embeddings is None:
        print("DEBUG: embeddings is None")
        return None, None

    requested = str(doc_id).strip()
    print("DEBUG: requested docId =", repr(requested))
    print("DEBUG: meta size =", len(meta))
    print("DEBUG: first 10 docIds =", [repr(str(item.get("docId")).strip()) for item in meta[:10]])

    for i, item in enumerate(meta):
        current = str(item.get("docId")).strip()
        if current == requested:
            print("DEBUG: MATCH FOUND at index", i, "collection =", item.get("collection"))
            return item, embeddings[i]

    print("DEBUG: NO MATCH FOUND")
    return None, None


def build_match_label(similarity: float) -> str:
    if similarity >= STRONG_MATCH_THRESHOLD:
        return "strong_match"
    elif similarity >= POTENTIAL_MATCH_THRESHOLD:
        return "potential_match"
    return "weak_match"


# =========================================
# Pydantic Models
# =========================================
class SearchRequest(BaseModel):
    docId: str
    top_k: int = 5


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
    top_k: int
    top_score: Optional[float] = None
    avg_top5_score: Optional[float] = None
    potential_matches_count: int
    search_time_ms: float
    index_version: Optional[str] = None
    index_id: Optional[str] = None
    results: List[SearchResult]


# =========================================
# Load artifacts on startup
# =========================================
load_artifacts()


# =========================================
# Routes
# =========================================
@app.get("/")
def root():
    return {
        "message": "Wadiah API is running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "artifacts_loaded": embeddings is not None and len(meta) > 0
    }


@app.get("/stats")
def get_stats():
    lost_count = sum(1 for item in meta if item.get("collection") == "lost")
    found_count = sum(1 for item in meta if item.get("collection") == "found")

    return {
        "indexed_count": len(meta),
        "lost_count": lost_count,
        "found_count": found_count,
        "index_id": index_info.get("index_id"),
        "index_version": index_info.get("index_version"),
        "last_index_update": index_info.get("built_at"),
        "model_name": index_info.get("model_name"),
        "img_size": index_info.get("img_size"),
        "embedding_shape": None if embeddings is None else list(embeddings.shape)
    }


@app.post("/search", response_model=SearchResponse)
def search_similar_items(payload: SearchRequest):
    start_time = time.perf_counter()

    query_meta, query_embedding = get_query_by_doc_id(payload.docId)

    if query_meta is None or query_embedding is None:
        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
        return {
            "query_docId": payload.docId,
            "query_collection": "unknown",
            "top_k": payload.top_k,
            "top_score": None,
            "avg_top5_score": None,
            "potential_matches_count": 0,
            "search_time_ms": elapsed_ms,
            "index_version": index_info.get("index_version"),
            "index_id": index_info.get("index_id"),
            "results": []
        }

    query_collection = query_meta.get("collection")
    target_collection = "found" if query_collection == "lost" else "lost"

    candidate_indices = [
        i for i, item in enumerate(meta)
        if item.get("collection") == target_collection
        and str(item.get("docId")).strip() != str(payload.docId).strip()
    ]

    if not candidate_indices:
        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
        return {
            "query_docId": payload.docId,
            "query_collection": query_collection,
            "top_k": payload.top_k,
            "top_score": None,
            "avg_top5_score": None,
            "potential_matches_count": 0,
            "search_time_ms": elapsed_ms,
            "index_version": index_info.get("index_version"),
            "index_id": index_info.get("index_id"),
            "results": []
        }

    candidate_embeddings = embeddings[candidate_indices]
    scores = cosine_similarity_matrix(query_embedding, candidate_embeddings)

    top_indices_local = np.argsort(-scores)[:payload.top_k]

    results = []
    for local_idx in top_indices_local:
        original_idx = candidate_indices[local_idx]
        item = meta[original_idx]

        similarity = float(scores[local_idx])

        results.append({
            "docId": item.get("docId"),
            "collection": item.get("collection"),
            "imageUrl": item.get("imageUrl"),
            "similarity": similarity,
            "match_label": build_match_label(similarity),
            "type": item.get("type"),
            "color": item.get("color"),
            "location": item.get("location"),
            "status": item.get("status")
        })

    top_score = float(np.max(scores)) if len(scores) > 0 else None
    avg_top5_score = float(np.mean(np.sort(scores)[-payload.top_k:])) if len(scores) > 0 else None
    potential_matches_count = int(np.sum(scores >= POTENTIAL_MATCH_THRESHOLD))
    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)

    return {
        "query_docId": payload.docId,
        "query_collection": query_collection,
        "top_k": payload.top_k,
        "top_score": top_score,
        "avg_top5_score": avg_top5_score,
        "potential_matches_count": potential_matches_count,
        "search_time_ms": elapsed_ms,
        "index_version": index_info.get("index_version"),
        "index_id": index_info.get("index_id"),
        "results": results
    }


@app.get("/debug/meta-check")
def debug_meta_check():
    return {
        "BASE_DIR": BASE_DIR,
        "ARTIFACTS_DIR": ARTIFACTS_DIR,
        "META_PATH": META_PATH,
        "META_EXISTS": os.path.exists(META_PATH),
        "META_SIZE": len(meta),
        "FIRST_5_DOCIDS": [str(item.get("docId")).strip() for item in meta[:5]],
        "EMBEDDINGS_EXISTS": os.path.exists(EMBEDDINGS_PATH),
        "INDEX_INFO_EXISTS": os.path.exists(INDEX_INFO_PATH),
        "PREPROCESS_CONFIG_EXISTS": os.path.exists(PREPROCESS_CONFIG_PATH),
    }