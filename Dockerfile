FROM python:3.9-buster as builder

WORKDIR /app

RUN echo "deb http://archive.debian.org/debian/ buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq-dev \
        gcc \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt


FROM python:3.9-slim-buster as runner

WORKDIR /app

RUN echo "deb http://archive.debian.org/debian/ buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local /root/.local
COPY --from=builder /app/requirements.txt .

COPY ./app ./app
COPY manage.py .
COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

ENV PATH=/root/.local/bin:$PATH

ENTRYPOINT ["./entrypoint.sh"]

CMD ["gunicorn", "--bind", "0.0.0.0:5555", "manage:app"]