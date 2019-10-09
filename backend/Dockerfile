FROM nginx:1.17.4

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y nginx-extras && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/
