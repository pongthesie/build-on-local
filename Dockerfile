FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

WORKDIR /opt/app

# ไลบรารีระบบที่มักจำเป็นสำหรับ opencv/paddle
RUN apt-get update && apt-get install -y --no-install-recommends \
      libglib2.0-0 libsm6 libxext6 libxrender1 libgl1 ca-certificates \
   && rm -rf /var/lib/apt/lists/*

# ใส่ wheelhouse + requirements
COPY wheels_offline_py312/ /wheels/
COPY requirements.txt /tmp/requirements.txt

# ติดตั้งจาก wheelhouse แบบไม่แตะ PyPI
RUN python -m pip install -U pip setuptools wheel \
 && python -m pip install --no-index --find-links=/wheels -r /tmp/requirements.txt

# คัดลอกซอร์ส (ปรับตามโปรเจ็กต์จริง)
COPY . /opt/app

# ตรวจสอบว่าลงครบ (ดีบัก—เอาออกได้ภายหลัง)
RUN python - <<'PY'
import importlib, sys
mods = ["flask","fastapi","uvicorn","sqlalchemy","paddle","paddleocr"]
for m in mods:
    try:
        importlib.import_module(m); print("OK:", m)
    except Exception as e:
        print("FAIL:", m, e); sys.exit(1)
print("All good.")
PY

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
