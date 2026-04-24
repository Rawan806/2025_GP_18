import sys
import time
from pathlib import Path

import requests

# مهم: عدلي هذا حسب مكان المشروع عندك إذا لزم
# هذا يضيف مجلد backend إلى sys.path حتى نقدر نستورد init_firestore
CURRENT_FILE = Path(__file__).resolve()
BACKEND_DIR = CURRENT_FILE.parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.firebase_config import init_firestore  # noqa: E402


API_BASE_URL = "http://127.0.0.1:8000"
COLLECTIONS = ["lostItems", "foundItems"]

# إذا تبين يعيد فهرسة كل شيء حتى الجاهز، خليها True
FORCE_REINDEX = False

# لو عندك عناصر كثيرة جدًا، خليه صغير شوي
SLEEP_BETWEEN_REQUESTS = 0.1


def has_image(data: dict) -> bool:
    image_url = (data.get("imageUrl") or "").strip()
    image_path = (data.get("imagePath") or "").strip()
    return bool(image_url or image_path)


def should_index(data: dict) -> bool:
    if FORCE_REINDEX:
        return has_image(data)

    if not has_image(data):
        return False

    is_indexed = data.get("isIndexed", False)
    index_status = str(data.get("indexStatus", "")).strip().lower()

    # نفهرس فقط إذا ليس جاهزًا
    if is_indexed is True and index_status == "ready":
        return False

    return True


def index_one(doc_id: str, collection: str) -> tuple[bool, str]:
    try:
        response = requests.post(
            f"{API_BASE_URL}/index-item",
            json={"docId": doc_id, "collection": collection},
            timeout=60,
        )
        if 200 <= response.status_code < 300:
            return True, response.text
        return False, f"{response.status_code}: {response.text}"
    except Exception as e:
        return False, str(e)


def main():
    db = init_firestore()

    total_docs = 0
    total_with_images = 0
    total_skipped = 0
    total_success = 0
    total_failed = 0

    print("=== Backfill indexing started ===")
    print(f"API_BASE_URL = {API_BASE_URL}")
    print(f"FORCE_REINDEX = {FORCE_REINDEX}")
    print()

    for collection in COLLECTIONS:
        print(f"\n--- Collection: {collection} ---")
        docs = list(db.collection(collection).stream())

        print(f"Found {len(docs)} docs in {collection}")

        for doc in docs:
            total_docs += 1
            data = doc.to_dict() or {}

            doc_id = str(data.get("docId") or doc.id).strip()

            if has_image(data):
                total_with_images += 1

            if not should_index(data):
                total_skipped += 1
                continue

            ok, msg = index_one(doc_id=doc_id, collection=collection)

            if ok:
                total_success += 1
                print(f"[OK] {collection}/{doc_id}")
            else:
                total_failed += 1
                print(f"[FAIL] {collection}/{doc_id} -> {msg}")

            time.sleep(SLEEP_BETWEEN_REQUESTS)

    print("\n=== Backfill indexing finished ===")
    print(f"Total docs: {total_docs}")
    print(f"Docs with images: {total_with_images}")
    print(f"Skipped: {total_skipped}")
    print(f"Indexed successfully: {total_success}")
    print(f"Failed: {total_failed}")


if __name__ == "__main__":
    main()