# WHY python:3.12-slim?
# slim = stripped OS packages = smaller attack surface
# Fewer packages = fewer CVEs = more secure image
# Industry standard for Python production containers
FROM python:3.12-slim

LABEL maintainer="devsecops-engineer"
LABEL version="1.0.0"
LABEL description="DevSecOps Flask Application"

# WHY these ENV vars?
# PYTHONDONTWRITEBYTECODE = no .pyc files (clean image)
# PYTHONUNBUFFERED = logs appear instantly in Docker/CloudWatch
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV APP_ENV=production

WORKDIR /app

# WHY copy requirements BEFORE code?
# Docker layer caching:
# If only code changes → pip install layer is REUSED
# Makes CI/CD pipeline builds much faster
COPY requirements.txt .

# WHY --no-cache-dir?
# Reduces final image size significantly
# Cache not needed after build
RUN pip install --upgrade pip --no-cache-dir && \
    pip install --no-cache-dir -r requirements.txt

COPY app.py .

# =====================================================
# CRITICAL SECURITY: Non-Root User
# WHY?
# Docker runs as ROOT by default (UID 0)
# If attacker exploits your app = they get ROOT
# ROOT inside container can lead to container escape
# Solution: dedicated non-root user limits damage
# =====================================================
RUN addgroup --system appgroup && \
    adduser --system \
            --ingroup appgroup \
            --no-create-home \
            appuser

# Give ownership of app files to our new user
RUN chown -R appuser:appgroup /app

# Switch to non-root — ALL following runs as appuser
USER appuser

# WHY EXPOSE only 5000?
# Principle of Least Privilege
# Only open ports the app actually needs
# Never expose debug ports, DB ports, admin ports
EXPOSE 5000

# WHY Gunicorn instead of python app.py?
# Production WSGI server — handles concurrent requests
# Flask dev server is NOT safe for production
# --workers 2 = good for t2.micro (1 CPU)
# --access-logfile - = logs to stdout (CloudWatch picks up)
CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "2", \
     "--timeout", "60", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app:app"]