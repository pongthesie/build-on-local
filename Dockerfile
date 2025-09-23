FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

WORKDIR /opt/app

# system libs ที่จำเป็น
RUN apt-get update && apt-get install -y --no-install-recommends \
      libglib2.0-0 libsm6 libxext6 libxrender1 libgl1 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# upgrade pip tools
RUN python -m pip install -U pip setuptools wheel

# ติดตั้งจาก requirements.txt (ดึงจาก PyPI)
COPY requirements.txt /tmp/requirements.txt
RUN python -m pip install --only-binary=:all: --prefer-binary -r /tmp/requirements.txt

# คัดลอกโค้ดเข้า image
COPY . /opt/app

# ตรวจสอบ import
# RUN python - <<'PY'
# import importlib, sys
# mods = ["flask","fastapi","uvicorn","sqlalchemy","paddle","paddleocr","tensorflow"]
# for m in mods:
#     try: importlib.import_module(m); print("OK:", m)
#     except Exception as e: print("FAIL:", m, e); sys.exit(1)
# PY


EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
