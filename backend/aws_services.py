"""
AWS DynamoDB + SNS integration for LifeLink Smart Ambulance System.

This module provides:
  - store_accident()   → writes accident data to DynamoDB
  - publish_alert()    → sends emergency SMS via SNS
  - get_accident()     → retrieves a single accident record
  - update_accident_status() → updates the status field

Requires environment variables:
  AWS_REGION           (default: ap-south-1)
  SNS_TOPIC_ARN        (your ambulance-alerts topic ARN)
  AWS_ACCESS_KEY_ID    (from Learner Lab credentials)
  AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN    (Learner Lab requires this)
"""

import os
import uuid
import datetime
import boto3
from botocore.exceptions import ClientError

# ---------- Configuration ----------
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "arn:aws:sns:us-east-1:098268776029:ambulance-alerts")
DYNAMODB_TABLE = "accidents"
S3_BUCKET = os.environ.get("S3_BUCKET", "lifelink-accident-images-098268776029")

# ---------- AWS Clients ----------
dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
sns_client = boto3.client("sns", region_name=AWS_REGION)
s3_client = boto3.client("s3", region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE)


def store_accident(
    vehicle_id: str,
    latitude: float,
    longitude: float,
    impact_force: float,
    status: str = "detected",
) -> dict:
    """
    Store an accident record in DynamoDB.

    Returns the full item dict including the generated accident_id.
    """
    accident_id = str(uuid.uuid4())
    timestamp = datetime.datetime.utcnow().isoformat() + "Z"

    item = {
        "accident_id": accident_id,
        "vehicle_id": vehicle_id,
        "latitude": str(latitude),
        "longitude": str(longitude),
        "impact_force": str(impact_force),
        "timestamp": timestamp,
        "status": status,
    }

    table.put_item(Item=item)
    return item


def publish_alert(latitude: float, longitude: float, accident_id: str = "", impact_force: float = 0.0, device_id: str = "") -> str:
    """
    Publish an emergency alert to the SNS topic.
    Sends a beautifully formatted plain text email with Google Maps link.

    Returns the SNS MessageId on success.
    """
    if not SNS_TOPIC_ARN:
        raise ValueError("SNS_TOPIC_ARN environment variable is not set")

    maps_url = f"https://www.google.com/maps?q={latitude},{longitude}"
    timestamp = datetime.datetime.utcnow().strftime("%B %d, %Y at %I:%M %p UTC")

    severity = "LOW"
    if impact_force >= 8.0:
        severity = "🔴 CRITICAL"
    elif impact_force >= 4.0:
        severity = "🟠 HIGH"
    elif impact_force >= 2.0:
        severity = "🟡 MEDIUM"
    else:
        severity = "🟢 LOW"

    message = (
        f"╔══════════════════════════════════════════════╗\n"
        f"║     🚨 LIFELINK EMERGENCY ALERT 🚨          ║\n"
        f"║     Smart Ambulance Detection System         ║\n"
        f"╚══════════════════════════════════════════════╝\n"
        f"\n"
        f"🚑  ACCIDENT DETECTED — IMMEDIATE RESPONSE REQUIRED\n"
        f"\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"  📋  INCIDENT DETAILS\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"\n"
        f"  ⚠️  Severity Level    :  {severity}\n"
        f"  💥  Impact Force      :  {impact_force}g\n"
        f"  📍  GPS Coordinates   :  {latitude}, {longitude}\n"
        f"  🔧  Device ID         :  {device_id or 'Unknown'}\n"
        f"  🆔  Accident ID       :  {accident_id}\n"
        f"  🕐  Detected At       :  {timestamp}\n"
        f"\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"  🗺️  VIEW ACCIDENT LOCATION ON MAP\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"\n"
        f"  👉  {maps_url}\n"
        f"\n"
        f"  (Click the link above to open Google Maps)\n"
        f"\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"  ⚡  ACTION REQUIRED\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"\n"
        f"  ✅  Dispatch nearest ambulance immediately\n"
        f"  ✅  Notify emergency medical team\n"
        f"  ✅  Monitor real-time updates on LifeLink dashboard\n"
        f"\n"
        f"╔══════════════════════════════════════════════╗\n"
        f"║  LifeLink — Saving Lives with Technology     ║\n"
        f"║  Powered by AWS (SNS + DynamoDB + EC2)       ║\n"
        f"╚══════════════════════════════════════════════╝\n"
    )

    response = sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject="🚨 LifeLink Emergency Alert — Accident Detected!",
    )
    return response["MessageId"]


def upload_accident_image(accident_id: str, image_bytes: bytes, content_type: str = "image/jpeg") -> dict:
    """
    Upload an accident scene image to S3.

    Returns dict with s3_key and public URL.
    """
    ext = "jpg"
    if "png" in content_type:
        ext = "png"
    elif "webp" in content_type:
        ext = "webp"

    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    s3_key = f"accidents/{accident_id}/{timestamp}.{ext}"

    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=image_bytes,
        ContentType=content_type,
        Metadata={
            "accident_id": accident_id,
            "uploaded_at": datetime.datetime.utcnow().isoformat() + "Z",
        },
    )

    # Generate a presigned URL valid for 7 days (for judges to view)
    presigned_url = s3_client.generate_presigned_url(
        "get_object",
        Params={"Bucket": S3_BUCKET, "Key": s3_key},
        ExpiresIn=604800,
    )

    return {
        "s3_key": s3_key,
        "s3_bucket": S3_BUCKET,
        "presigned_url": presigned_url,
    }


def list_accident_images(accident_id: str) -> list:
    """List all images stored in S3 for a given accident."""
    prefix = f"accidents/{accident_id}/"
    response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)

    images = []
    for obj in response.get("Contents", []):
        url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": S3_BUCKET, "Key": obj["Key"]},
            ExpiresIn=604800,
        )
        images.append({
            "s3_key": obj["Key"],
            "size_bytes": obj["Size"],
            "last_modified": obj["LastModified"].isoformat(),
            "presigned_url": url,
        })
    return images


def get_accident(accident_id: str) -> dict | None:
    """Retrieve a single accident record by ID."""
    response = table.get_item(Key={"accident_id": accident_id})
    return response.get("Item")


def update_accident_status(accident_id: str, new_status: str) -> dict:
    """Update the status of an existing accident record."""
    response = table.update_item(
        Key={"accident_id": accident_id},
        UpdateExpression="SET #s = :val, updated_at = :ts",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":val": new_status,
            ":ts": datetime.datetime.utcnow().isoformat() + "Z",
        },
        ReturnValues="ALL_NEW",
    )
    return response["Attributes"]
