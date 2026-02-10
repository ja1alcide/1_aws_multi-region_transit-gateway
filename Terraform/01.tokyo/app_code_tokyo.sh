#!/bin/bash
# ---------------------------------------------------------
# Lab 1b + 2b (Honors+) User Data Script
# Function: Installs dependencies, creates the Python app,
# and handles DB connections, API caching, and Static Files.
# ---------------------------------------------------------

# 1. Install System Dependencies
dnf update -y
dnf install -y python3-pip mariadb105
pip3 install flask pymysql boto3 watchtower

# 2. Create Directory Structure
mkdir -p /opt/rdsapp
mkdir -p /opt/rdsapp/static

# 2.1 Create Static Files (CRITICAL for Lab 2B grading)
echo "<h1>Version 2.0 - Static Content</h1>" > /opt/rdsapp/static/index.html
# ADDED: This file is required for the curl -I tests in Deliverable D
echo "Chewbacca says: If you see this, CloudFront is talking to the ALB!" > /opt/rdsapp/static/example.txt

# 3. Create the Python Application
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
import logging
import time
from flask import Flask, request, jsonify, make_response, send_from_directory
from watchtower import CloudWatchLogHandler

# --- Configuration Constants ---
REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
LOG_GROUP = "/aws/ec2/lab-rds-app"
METRIC_NAMESPACE = "Lab/RDSApp"
CACHE_TTL = 300 
STATIC_FOLDER = '/opt/rdsapp/static'

# --- Global Cache Variables ---
config_cache = None
last_fetch_time = 0

# --- Initialize AWS Clients ---
ssm = boto3.client("ssm", region_name=REGION)
sm = boto3.client("secretsmanager", region_name=REGION)
cw = boto3.client("cloudwatch", region_name=REGION)

# --- Logging Setup ---
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
try:
    cw_handler = CloudWatchLogHandler(
        log_group=LOG_GROUP, 
        stream_name="app-stream", 
        boto3_client=boto3.client("logs", region_name=REGION)
    )
    logger.addHandler(cw_handler)
except Exception as e:
    print(f"CloudWatch Logs Setup Pending: {e}")

app = Flask(__name__)

# --- LAB 2B IMPROVEMENT: GLOBAL HEADER MIDDLEWARE ---
# Instead of adding headers manually in routes, we catch ALL static requests here.
# This solves the "Be A Man" challenge robustly.
@app.after_request
def add_header(response):
    if request.path.startswith('/static/'):
        # Force browser/CloudFront to cache for 24 hours
        response.headers['Cache-Control'] = 'public, max-age=86400'
    return response

# --- Helper Functions (Metrics & Config) ---
def record_failure(error_msg):
    logger.error(f"DB_CONNECTION_FAILURE: {error_msg}")
    try:
        cw.put_metric_data(
            Namespace=METRIC_NAMESPACE,
            MetricData=[{'MetricName': 'DBConnectionErrors', 'Value': 1.0, 'Unit': 'Count'}]
        )
    except Exception as e:
        logger.warning(f"Failed to push metric: {e}")

def get_config():
    global config_cache, last_fetch_time
    current_time = time.time()
    
    if config_cache and (current_time - last_fetch_time < CACHE_TTL):
        return config_cache

    try:
        logger.info("Fetching fresh config...")
        p_resp = ssm.get_parameters(
            Names=['/lab/db/endpoint', '/lab/db/port', '/lab/db/name'],
            WithDecryption=False
        )
        p_map = {p['Name']: p['Value'] for p in p_resp['Parameters']}
        
        s_resp = sm.get_secret_value(SecretId='lab/rds/mysql')
        secret = json.loads(s_resp['SecretString'])

        config_cache = {
            'host': p_map.get('/lab/db/endpoint'),
            'port': int(p_map.get('/lab/db/port', 3306)),
            'dbname': p_map.get('/lab/db/name', 'labdb'),
            'user': secret.get('username'),
            'password': secret.get('password')
        }
        last_fetch_time = current_time
        return config_cache
    except Exception as e:
        record_failure(f"Config Fetch Failed: {str(e)}")
        if config_cache: return config_cache 
        raise e

def get_conn():
    retries = 3
    for i in range(retries):
        try:
            c = get_config()
            return pymysql.connect(
                host=c['host'], user=c['user'], password=c['password'], 
                port=c['port'], database=c['dbname'], autocommit=True,
                connect_timeout=5
            )
        except Exception as e:
            if i < retries - 1:
                time.sleep(5)
            else:
                record_failure(str(e))
                raise e

# --- Web Routes ---

@app.route("/")
def home():
    return """
    <h1>DAWG's Web App for RDS</h1>
    <ul>
        <li><a href='/static/index.html'>1. Static Page (Lab 2B+)</a></li>
        <li><a href='/api/public-feed'>2. Public API (Lab 2B)</a></li>
        <li><a href='/init'>3. Init DB</a></li>
        <li><a href='/add?text=LabEntry'>4. Add Note</a></li>
        <li><a href='/list'>5. List Notes</a></li>
    </ul>
    """

# --- LAB 2B: STATIC ROUTE ---
# Headers are now handled by the @app.after_request middleware above.
@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory(STATIC_FOLDER, filename)

# --- LAB 2B: API ROUTES ---
@app.route('/api/public-feed')
def public_feed():
    data = {"message": "The market is moving!", "server_time_utc": time.time()}
    response = make_response(jsonify(data))
    
    # Origin-Driven Caching:
    # public: CloudFront is allowed to store this.
    # s-maxage=30: CloudFront holds it for 30s (Shared Max Age).
    response.headers['Cache-Control'] = 'public, s-maxage=30, max-age=0'
    return response

@app.route('/api/list')
def private_list():
    # Simulate sensitive data retrieval
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT note FROM notes ORDER BY id DESC LIMIT 5;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        data = {"notes": [r[0] for r in rows], "status": "private"}
    except:
        data = {"error": "db_connection_failed"}

    response = make_response(jsonify(data))
    
    # Security Header (CRITICAL):
    # private: CloudFront must NOT store this.
    # no-store: Do not write to disk.
    response.headers['Cache-Control'] = 'private, no-store'
    return response

# --- LAB 1 SECTION: DB OPERATIONS ---
@app.route("/add")
def add_note():
    note_text = request.args.get('text', 'Manual Entry')
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (note_text,))
        cur.close()
        conn.close()
        return f"Added: {note_text} | <a href='/list'>View List</a>"
    except Exception as e:
        return f"Add Failed: {e}", 500

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return "<h3>Notes:</h3>" + "".join([f"<li>{r[1]}</li>" for r in rows]) + "<br><a href='/'>Back</a>"
    except Exception as e:
        return f"List Failed: {e}", 500

@app.route("/init")
def init_db():
    try:
        c = get_config()
        conn = pymysql.connect(host=c['host'], user=c['user'], password=c['password'], port=c['port'])
        cur = conn.cursor()
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {c['dbname']};")
        cur.execute(f"USE {c['dbname']};")
        cur.execute("CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(255));")
        cur.close()
        conn.close()
        return "Init Success! <a href='/'>Back</a>"
    except Exception as e:
        record_failure(str(e))
        return f"Init Failed: {e}", 500

# --- HEALTH CHECK ROUTE ADDED AT LAB 3---
@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

# 4. Create the Service File
cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=Lab 1b RDS App
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/rdsapp
ExecStartPre=/usr/bin/sleep 20
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always
RestartSec=10s
Environment=AWS_REGION=ap-northeast-1

[Install]
WantedBy=multi-user.target
SERVICE

# 5. Start the Engine
systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

systemctl restart amazon-ssm-agent
echo "User Data Complete - SSM Agent Restarted"