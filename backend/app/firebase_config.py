import os
import firebase_admin
from firebase_admin import credentials, firestore

def init_firestore():
    if not firebase_admin._apps:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        key_path = os.path.join(base_dir, "serviceAccountKey.json")

        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)

    return firestore.client()