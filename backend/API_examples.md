# API Examples

## Search Example

Request:
{
  "docId": "1764835820",
  "top_k": 5
}

Response:
{
  "results": [
    {
      "docId": "1764835001",
      "similarity": 0.82,
      "imageUrl": "https://example.com/image1.jpg",
      "collection": "found"
    },
    {
      "docId": "1764835123",
      "similarity": 0.79,
      "imageUrl": "https://example.com/image2.jpg",
      "collection": "lost"
    }
  ],
  "stats": {
    "top_score": 0.82,
    "avg_top5_score": 0.78,
    "potential_matches_count": 1,
    "search_time_ms": 98,
    "index_version": "v1.0"
  }
}

---

## Stats Example

GET /stats

Response:
{
  "lost_count": 120,
  "found_count": 95,
  "indexed_count": 215,
  "index_version": "v1.0"
}
