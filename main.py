# main.py
"""
Example app ที่เรียกใช้ library ตาม requirements.txt
- Flask : สร้าง endpoint เล็ก ๆ
- FastAPI + Uvicorn : สร้าง API endpoint
- SQLAlchemy : ใช้ in-memory SQLite DB
- PaddlePaddle + PaddleOCR : ลอง import และ print เวอร์ชัน
- TensorFlow : ลอง import และ print เวอร์ชัน
"""

from flask import Flask
from fastapi import FastAPI
from fastapi.middleware.wsgi import WSGIMiddleware
import uvicorn
from sqlalchemy import create_engine, text

import paddle
from paddleocr import PaddleOCR
import tensorflow as tf

# --- Flask app ---
flask_app = Flask(__name__)
@flask_app.route("/")
def hello_flask():
    return "Hello from Flask!"

# --- FastAPI app ---
fastapi_app = FastAPI()
@fastapi_app.get("/hello")
def hello_fastapi():
    return {"msg": "Hello from FastAPI!"}

# ✅ mount Flask เข้า FastAPI ตอน import (uvicorn จะเห็นเลย)
fastapi_app.mount("/flask", WSGIMiddleware(flask_app))

# ✅ export เป็นตัวแปร 'app' ให้ uvicorn ใช้
app = fastapi_app

# --- SQLAlchemy Demo ---
def test_sqlalchemy():
    engine = create_engine("sqlite:///:memory:", echo=False)
    with engine.connect() as conn:
        conn.execute(text("CREATE TABLE demo (id INTEGER PRIMARY KEY, name TEXT)"))
        conn.execute(text("INSERT INTO demo (name) VALUES ('Alice')"))
        result = conn.execute(text("SELECT * FROM demo")).fetchall()
        print("SQLAlchemy rows:", result)

# --- PaddleOCR Demo ---
def test_paddle():
    print("Paddle version:", paddle.__version__)
    ocr = PaddleOCR(use_angle_cls=True, lang="en", use_gpu=False)
    print("PaddleOCR ready:", ocr is not None)

# --- TensorFlow Demo ---
def test_tf():
    print("TensorFlow version:", tf.__version__)

if __name__ == "__main__":
    print("=== Run library checks ===")
    test_sqlalchemy()
    test_paddle()
    test_tf()
    print("=== Starting servers ===")
    uvicorn.run(app, host="0.0.0.0", port=8000)
