import requests
import json
import time

BASE_URL = "http://localhost:8000"

def run_test():
    # 1. Register a user
    user_data = {
        "email": f"test_ocr_{int(time.time())}@example.com",
        "password": "Password123!",
        "full_name": "Test User",
        "phone": f"+123{int(time.time())}",
        "role": "patient"
    }
    print("Registering user...")
    r = requests.post(f"{BASE_URL}/auth/register", json=user_data)
    if r.status_code != 201:
        print("Registration failed:", r.text)
        return

    # 2. Login
    print("Logging in...")
    login_data = {
        "username": user_data["phone"],
        "password": user_data["password"]
    }
    r = requests.post(f"{BASE_URL}/auth/login", data=login_data)
    if r.status_code != 200:
        print("Login failed:", r.text)
        return
    token = r.json()["access_token"]
    
    # 3. Upload image
    print("Uploading image...")
    image_path = r"C:\Users\there\.gemini\antigravity-ide\brain\30efc359-a910-4306-b5af-c586a1a19b02\handwritten_prescription_block_1782538987868.png"
    
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    with open(image_path, "rb") as f:
        files = {"file": ("handwritten_prescription.png", f, "image/png")}
        r = requests.post(f"{BASE_URL}/ai/process-prescription", files=files, headers=headers)
        
    print(f"Status Code: {r.status_code}")
    print("Response:")
    print(json.dumps(r.json(), indent=2))

if __name__ == "__main__":
    run_test()
