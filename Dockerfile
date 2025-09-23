FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=180 \
    OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

WORKDIR /opt/app

# ติดตั้ง system libraries ที่ Paddle/Opencv ใช้
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl dnsutils \
      libglib2.0-0 libsm6 libxext6 libxrender1 libgl1 \
 && rm -rf /var/lib/apt/lists/*

# อัปเดต pip tools
RUN python -m pip install -U pip setuptools wheel

# toggle เพื่อตัด TensorFlow ออก (ถ้าต้องการลด size)
ARG WITH_TF=1

# requirements
COPY requirements.txt /tmp/requirements.txt

# ติดตั้ง Paddle/PaddleOCR แยกออกมาก่อน (ชัดเจนว่าพังตรงไหน)
RUN set -eux; \
    python -m pip -vvv install --only-binary=:all: --prefer-binary paddlepaddle==2.6.1 paddleocr==2.9.1; \
    if [ "$WITH_TF" = "1" ]; then \
        python -m pip -vvv install --only-binary=:all: --prefer-binary tensorflow-cpu==2.16.1; \
    else \
        echo "Skip tensorflow-cpu"; \
    fi

# ติดตั้ง package อื่น ๆ ตาม requirements.txt
RUN set -eux; \
    if ! python -m pip -vvv install --only-binary=:all: --prefer-binary -r /tmp/requirements.txt; then \
        echo '--- Fallback: allow source builds ---'; \
        python -m pip -vvv install -r /tmp/requirements.txt; \
    fi

# ใส่โค้ดเข้า image
COPY . /opt/app

EXPOSE 8000
CMD ["uvicorn","main:app","--host","0.0.0.0","--port","8000"]
