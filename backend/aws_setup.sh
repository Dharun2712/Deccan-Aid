#!/bin/bash
# =============================================================================
# AWS SETUP SCRIPT — LifeLink Smart Ambulance Accident Detection System
# Region: ap-south-1 (Mumbai)
# Budget: < $50 (AWS Academy Learner Lab)
# =============================================================================
# PREREQUISITES:
#   1. AWS CLI v2 installed and configured with your Learner Lab credentials
#   2. Run: aws configure
#      - Access Key ID:     (from Learner Lab → AWS Details)
#      - Secret Access Key: (from Learner Lab → AWS Details)
#      - Default region:    ap-south-1
#      - Output format:     json
#
# NOTE: AWS Academy Learner Lab has restrictions:
#   - You CANNOT create IAM roles/users (use the pre-assigned LabRole)
#   - You CANNOT create VPCs (use the default VPC)
#   - Session credentials expire; re-export them each session
# =============================================================================

set -euo pipefail

REGION="us-east-1"
KEY_NAME="ambulance-backend-key"
SG_NAME="ambulance-backend-sg"
INSTANCE_NAME="ambulance-backend"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0c7217cdde317cfec"   # Ubuntu 22.04 LTS in us-east-1 (verify in console)

echo "============================================="
echo " LifeLink — AWS Infrastructure Setup"
echo " Region: ${REGION}"
echo "============================================="

# ---------------------------------------------------------
# 1. KEY PAIR
# ---------------------------------------------------------
echo ""
echo "[1/5] Creating EC2 key pair: ${KEY_NAME}"

aws ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --key-type rsa \
    --query 'KeyMaterial' \
    --output text \
    --region "${REGION}" > "${KEY_NAME}.pem"

chmod 400 "${KEY_NAME}.pem"
echo "  ✅ Key pair saved to ${KEY_NAME}.pem"

# ---------------------------------------------------------
# 2. SECURITY GROUP
# ---------------------------------------------------------
echo ""
echo "[2/5] Creating security group: ${SG_NAME}"

# Get default VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query 'Vpcs[0].VpcId' \
    --output text \
    --region "${REGION}")

echo "  Default VPC: ${VPC_ID}"

SG_ID=$(aws ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "Security group for LifeLink ambulance backend - SSH, HTTP, FastAPI" \
    --vpc-id "${VPC_ID}" \
    --query 'GroupId' \
    --output text \
    --region "${REGION}")

echo "  Security Group ID: ${SG_ID}"

# Ingress rules
echo "  Adding ingress rules..."

# SSH (port 22)
aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region "${REGION}"
echo "    ✅ SSH (22) — open"

# HTTP (port 80)
aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region "${REGION}"
echo "    ✅ HTTP (80) — open"

# FastAPI (port 8000)
aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 8000 \
    --cidr 0.0.0.0/0 \
    --region "${REGION}"
echo "    ✅ FastAPI (8000) — open"

# ---------------------------------------------------------
# 3. EC2 INSTANCE
# ---------------------------------------------------------
echo ""
echo "[3/5] Launching EC2 instance: ${INSTANCE_NAME}"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${SG_ID}" \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":8,"VolumeType":"gp3"}}]' \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region "${REGION}")

echo "  Instance ID: ${INSTANCE_ID}"
echo "  Waiting for instance to be running..."

aws ec2 wait instance-running \
    --instance-ids "${INSTANCE_ID}" \
    --region "${REGION}"

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "${INSTANCE_ID}" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region "${REGION}")

echo "  ✅ Instance running!"
echo "  🌐 Public IP: ${PUBLIC_IP}"

# ---------------------------------------------------------
# 4. DYNAMODB TABLE
# ---------------------------------------------------------
echo ""
echo "[4/5] Creating DynamoDB table: accidents"

aws dynamodb create-table \
    --table-name accidents \
    --attribute-definitions \
        AttributeName=accident_id,AttributeType=S \
    --key-schema \
        AttributeName=accident_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"

echo "  Waiting for table to become ACTIVE..."

aws dynamodb wait table-exists \
    --table-name accidents \
    --region "${REGION}"

echo "  ✅ DynamoDB table 'accidents' is ACTIVE"

# ---------------------------------------------------------
# 5. SNS TOPIC
# ---------------------------------------------------------
echo ""
echo "[5/5] Creating SNS topic: ambulance-alerts"

TOPIC_ARN=$(aws sns create-topic \
    --name ambulance-alerts \
    --query 'TopicArn' \
    --output text \
    --region "${REGION}")

echo "  ✅ SNS Topic ARN: ${TOPIC_ARN}"

# ---------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------
echo ""
echo "============================================="
echo " ✅ SETUP COMPLETE"
echo "============================================="
echo ""
echo " EC2 Instance ID : ${INSTANCE_ID}"
echo " EC2 Public IP   : ${PUBLIC_IP}"
echo " Key Pair File   : ${KEY_NAME}.pem"
echo " Security Group  : ${SG_ID}"
echo " DynamoDB Table  : accidents"
echo " SNS Topic ARN   : ${TOPIC_ARN}"
echo ""
echo " SSH command:"
echo "   ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""
echo " FastAPI URL (after deployment):"
echo "   http://${PUBLIC_IP}:8000"
echo ""
echo " Next steps:"
echo "   1. Subscribe a phone to SNS (see aws_commands_reference.md)"
echo "   2. Deploy backend (see deploy.sh)"
echo "   3. Update Flutter app API base URL to http://${PUBLIC_IP}:8000"
echo "============================================="
