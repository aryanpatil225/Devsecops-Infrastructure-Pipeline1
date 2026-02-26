#!/bin/bash

# System update and Docker install
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Wait for Docker
sleep 10

# Create app directory
mkdir -p /opt/flaskapp

# Write Flask app
cat > /opt/flaskapp/app.py << 'SCRIPT'
from flask import Flask, jsonify
import os
app = Flask(__name__)
ENV = os.environ.get("APP_ENV", "production")
VER = os.environ.get("APP_VERSION", "1.0.0")

@app.route("/")
def home():
    return jsonify({"message": "DevSecOps App on AWS", "environment": ENV, "status": "running", "version": VER})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/version")
def version():
    return jsonify({"version": VER}), 200
SCRIPT

# Write requirements
cat > /opt/flaskapp/requirements.txt << 'SCRIPT'
flask==3.0.3
gunicorn==22.0.0
SCRIPT

# Run Flask in Docker
docker run -d \
  --name flask-app \
  --restart unless-stopped \
  -p 5000:5000 \
  -v /opt/flaskapp:/app \
  -w /app \
  -e APP_ENV=production \
  -e APP_VERSION=1.0.0 \
  python:3.12-slim \
  sh -c "pip install --no-cache-dir -r requirements.txt && gunicorn --bind 0.0.0.0:5000 --workers 2 app:app"