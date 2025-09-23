FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=180

WORKDIR /opt/app

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl dnsutils \
      libglib2.0-0 libsm6 libxext6 libxrender1 libgl1 \
 && rm -rf /var/lib/apt/lists/*

RUN python -m pip install -U pip setuptools wheel

# toggle เพื่อตัด TensorFlow ออกกรณีมีปัญหา wheel/ทรัพยากร
ARG WITH_TF=1

COPY requirements.txt /tmp/requirements.txt

# 1) ติดตั้งตัวใหญ่/เสี่ยงเป็นรายตัวก่อน (เห็น error ชัด)
#    ใช้ --only-binary ก่อน ถ้าพังจะรู้ว่าตัวไหนไม่มี wheel
RUN set -eux; \
    python -m pip -vvv install --only-binary=:all: --prefer-binary paddlepaddle==2.6.1 paddleocr==2.9.1; \
    if [ "$WITH_TF" = "1" ]; then \
        python -m pip -vvv install --only-binary=:all: --prefer-binary tensorflow-cpu==2.16.1; \
    else \
        echo "Skip tensorflow-cpu"; \
    fi

# 2) ติดตั้งที่เหลือจาก requirements.txt
#    เริ่มแบบ binary-only; ถ้าล้ม -> fallback ยอม build จากซอร์สเฉพาะตัวที่ไม่มี wheel
RUN set -eux; \
    if ! python -m pip -vvv install --only-binary=:all: --prefer-binary -r /tmp/requirements.txt; then \
        echo '--- Fallback: allow source builds for remaining packages ---'; \
        python -m pip -vvv install -r /tmp/requirements.txt; \
    fi

COPY . /opt/app

EXPOSE 8000
CMD ["uvicorn","main:app","--host","0.0.0.0","--port","8000"]
