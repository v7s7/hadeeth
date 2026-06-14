#!/usr/bin/env python3
"""
Run once to store the FCM service account in Firestore.
Usage:
    pip3 install firebase-admin
    python3 setup_fcm.py
"""

import json, sys, os

KEY_PATH = os.path.join(os.path.dirname(__file__),
                        "hadeeth-19906-firebase-adminsdk-fbsvc-0eea7a2884.json")

if not os.path.exists(KEY_PATH):
    print(f"ERROR: key file not found at:\n  {KEY_PATH}")
    print("\nMove the downloaded service account JSON next to this script and re-run.")
    sys.exit(1)

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("Installing firebase-admin…")
    os.system("pip3 install firebase-admin")
    import firebase_admin
    from firebase_admin import credentials, firestore

with open(KEY_PATH) as f:
    sa_json = f.read()
    sa = json.loads(sa_json)

cred = credentials.Certificate(KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

db.collection("config").document("fcm_v1").set({
    "serviceAccountJson": sa_json,
})

print(f"\n✅ Done! Written to Firestore: config/fcm_v1")
print(f"   project : {sa['project_id']}")
print(f"   email   : {sa['client_email']}")
print("\nYou can now delete the .json key file from this folder.")
