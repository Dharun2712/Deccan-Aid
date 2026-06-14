#!/bin/bash
# =============================================================================
# DEPLOY LifeLink FastAPI Backend to EC2
# =============================================================================
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh <EC2_PUBLIC_IP>
#
# Prerequisites:
#   - ambulance-backend-key.pem in current directory
#   - EC2 instance running Ubuntu 22.04
# =============================================================================

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: ./deploy.sh <EC2_PUBLIC_IP>"
    exit 1
fi

EC2_IP="$1"
KEY_FILE="ambulance-backend-key.pem"
SSH_USER="ubuntu"
SSH_CMD="ssh -i ${KEY_FILE} -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_IP}"
SCP_CMD="scp -i ${KEY_FILE} -o StrictHostKeyChecking=no"

echo "============================================="
echo " Deploying LifeLink to ${EC2_IP}"
echo "============================================="

# ---------------------------------------------------------
# Step 1: Install system dependencies
# ---------------------------------------------------------
echo ""
echo "[1/4] Installing system packages..."

${SSH_CMD} << 'REMOTE_SCRIPT'
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv git
echo "  ✅ System packages installed"
REMOTE_SCRIPT

# ---------------------------------------------------------
# Step 2: Upload backend files
# ---------------------------------------------------------
echo ""
echo "[2/4] Uploading backend files..."

# Create remote directory
${SSH_CMD} "mkdir -p ~/lifelink/backend"

# Upload all Python files + requirements
${SCP_CMD} \
    app_fastapi.py \
    aws_services.py \
    models.py \
    requirements_fastapi.txt \
    "${SSH_USER}@${EC2_IP}:~/lifelink/backend/"

# Upload models directory if exists
if [ -d "models" ]; then
    ${SSH_CMD} "mkdir -p ~/lifelink/backend/models"
    ${SCP_CMD} -r models/ "${SSH_USER}@${EC2_IP}:~/lifelink/backend/models/"
fi

echo "  ✅ Files uploaded"

# ---------------------------------------------------------
# Step 3: Set up Python environment
# ---------------------------------------------------------
echo ""
echo "[3/4] Setting up Python virtual environment..."

${SSH_CMD} << 'REMOTE_SCRIPT'
cd ~/lifelink/backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements_fastapi.txt
pip install boto3
echo "  ✅ Python environment ready"
REMOTE_SCRIPT

# ---------------------------------------------------------
# Step 4: Start FastAPI server
# ---------------------------------------------------------
echo ""
echo "[4/4] Starting FastAPI server..."

${SSH_CMD} << REMOTE_SCRIPT
cd ~/lifelink/backend
source venv/bin/activate

# Create systemd service for persistence
sudo tee /etc/systemd/system/lifelink.service > /dev/null << 'SERVICE'
[Unit]
Description=LifeLink FastAPI Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/lifelink/backend
Environment="PATH=/home/ubuntu/lifelink/backend/venv/bin:/usr/bin"
Environment="AWS_REGION=us-east-1"
Environment="SNS_TOPIC_ARN=${SNS_TOPIC_ARN:-}"
ExecStart=/home/ubuntu/lifelink/backend/venv/bin/uvicorn app_fastapi:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable lifelink
sudo systemctl start lifelink
echo "  ✅ FastAPI server running on port 8000"
REMOTE_SCRIPT

echo ""
echo "============================================="
echo " ✅ DEPLOYMENT COMPLETE"
echo "============================================="
echo ""
echo " API: http://${EC2_IP}:8000"
echo " Docs: http://${EC2_IP}:8000/docs"
echo ""
echo " Manage the service:"
echo "   ${SSH_CMD} 'sudo systemctl status lifelink'"
echo "   ${SSH_CMD} 'sudo systemctl restart lifelink'"
echo "   ${SSH_CMD} 'sudo journalctl -u lifelink -f'"
echo "============================================="
