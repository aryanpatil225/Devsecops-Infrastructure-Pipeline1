import os
import logging
from flask import Flask, jsonify

# WHY: Logging records every request and error.
# In production this feeds into AWS CloudWatch
# for monitoring, alerting, and incident response.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

app = Flask(__name__)

# WHY environment variables?
# Never hardcode secrets or config in source code.
# This follows the 12-Factor App methodology.
# Config is injected at runtime — safe to push to GitHub.
APP_ENV     = os.environ.get("APP_ENV", "production")
APP_PORT    = int(os.environ.get("APP_PORT", 5000))
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
SECRET_KEY  = os.environ.get("SECRET_KEY", "change-me-in-prod")

app.config["SECRET_KEY"] = SECRET_KEY


@app.route("/")
def home():
    logging.info("Home endpoint accessed")
    return jsonify({
        "message": "DevSecOps Flask App - Running on AWS",
        "environment": APP_ENV,
        "status": "running",
        "version": APP_VERSION
    })


# WHY /health endpoint?
# Load balancers use this to check if app is alive.
# Required for zero-downtime deployments.
# AWS ALB, monitoring tools all depend on this.
@app.route("/health")
def health():
    logging.info("Health check called")
    return jsonify({"status": "healthy"}), 200


@app.route("/version")
def version():
    return jsonify({"version": APP_VERSION}), 200


if __name__ == "__main__":
    # WHY debug=False?
    # Debug mode exposes stack traces to users.
    # Attackers use this to map your app internals.
    # NEVER run debug=True in production.
    app.run(host="0.0.0.0", port=APP_PORT, debug=False)