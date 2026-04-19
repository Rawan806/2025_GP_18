# Wadiah Data & API Overview

## Overview
This system performs similarity-based retrieval for lost and found items using image embeddings.

---

## Data Source

The system uses:
- embeddings.npy (image vectors)
- meta.json (item metadata)

---

## API Endpoints

### POST /search

Request:
{
  "docId": "123456",
  "top_k": 5
}

Response:
{
  "results": [
    {
      "docId": "987654",
      "similarity": 0.87,
      "imageUrl": "...",
      "collection": "found"
    }
  ],
  "stats": {
    "top_score": 0.87,
    "avg_top5_score": 0.81,
    "potential_matches_count": 2,
    "search_time_ms": 120,
    "index_version": "v1.0"
  }
}

---

### GET /stats

Response:
{
  "lost_count": 120,
  "found_count": 95,
  "indexed_count": 215,
  "index_version": "v1.0"
}

---

## Threshold Logic

- strong_match: similarity >= 0.85  
- potential_match: similarity >= 0.75  
- weak_match: similarity < 0.75
