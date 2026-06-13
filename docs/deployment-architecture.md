# SmartAid Deployment Architecture

## 1. Deployment Goals
The primary goal of the SmartAid infrastructure is to ensure a highly available, secure, and scalable emergency response ecosystem. Key objectives include:
- **Zero Downtime**: Ensuring emergency services are accessible 24/7.
- **Low Latency**: Minimizing response times for real-time tracking and SOS requests.
- **Scalability**: Ability to handle sudden spikes in traffic during major emergencies.
- **Security & Compliance**: Securing patient data and complying with healthcare regulations.
- **Resilience**: Implementing robust disaster recovery and automatic failover mechanisms.

## 2. Infrastructure Overview
SmartAid employs a modern, cloud-native architecture deployed on Google Cloud Platform (GCP). The system utilizes a microservices approach with a Flutter mobile frontend communicating via FastAPI backend services, managed and orchestrated through Google Cloud Run for serverless scaling.

## 3. High-Level Topology
The deployment topology is segregated into distinct layers to enforce security and manageability:
- **Presentation Layer**: Flutter mobile applications for users and responders.
- **Edge Layer**: Cloud Load Balancing and API Gateway handling ingress traffic, SSL termination, and basic DDoS protection.
- **Application Layer**: Containerized FastAPI microservices deployed on Cloud Run, handling business logic and real-time Socket.IO communication.
- **Data Layer**: MongoDB Atlas for persistent storage and Firebase Authentication for identity management.
- **AI & Integration Layer**: Google Gemini for AI-driven insights and Google Maps Platform for geolocation services.

## 4. Cloud Components (Google Cloud Services)
- **Cloud Run**: Hosts the FastAPI backend and Socket.IO servers.
- **Cloud Load Balancing**: Distributes incoming traffic globally.
- **Cloud Armor**: Provides web application firewall (WAF) and DDoS protection.
- **Secret Manager**: Securely stores API keys, database credentials, and service account keys.
- **Cloud Storage**: Stores static assets and user-uploaded media.
- **VPC Serverless Access**: Enables secure, private communication between Cloud Run and other internal services.

## 5. Network Architecture
The network is designed around a zero-trust model.

```mermaid
graph TD
    Client[Mobile App / Flutter] -->|HTTPS / WSS| CDN[Cloud CDN & Load Balancer]
    CDN --> WAF[Cloud Armor]
    WAF --> API[API Gateway / Ingress]
    API -->|VPC Connector| Backend[Cloud Run: FastAPI & Socket.IO]
    Backend -->|Private Link| Mongo[MongoDB Atlas]
    Backend -->|Secure API| Firebase[Firebase Auth]
    Backend -->|Secure API| Gemini[Google Gemini AI]
    Backend -->|Secure API| Maps[Google Maps]
```

### Trust Boundaries
- **Public Zone**: Client devices to Load Balancer. All data is encrypted via TLS 1.3.
- **DMZ Zone**: Load Balancer to Cloud Run instances. Protected by Cloud Armor policies.
- **Private Zone**: Cloud Run to MongoDB Atlas (via VPC Peering/PrivateLink). No internet access allowed directly to the database.

---

## 6. Containerization Strategy & Docker Architecture
SmartAid relies on Docker for containerizing the FastAPI and Socket.IO microservices.
- **Base Image**: Lightweight `python:3.11-slim` to minimize the attack surface.
- **Multi-Stage Builds**: Used to separate build dependencies from runtime dependencies, optimizing image size and security.
- **Stateless Architecture**: Containers do not store any local state. All state is externalized to MongoDB Atlas or managed via Socket.IO Redis adapters (if scaled).

## 7. Environment Strategy
SmartAid maintains strict environment separation to ensure code stability from development to production.

- **Development**: Local environment utilizing Docker Compose. Connects to a local MongoDB instance or a dedicated dev-cloud database.
- **Staging**: A mirror of the production environment. Used for QA, integration testing, and client sign-off. Deployed to a separate GCP project to enforce absolute isolation.
- **Production**: The live environment serving real SOS requests, ambulance tracking, and hospital coordination.

## 8. Configuration Management
Environment-specific configurations are managed via `.env` files. Configuration inheritance is used where possible, with specific overrides per environment.

### `.env.development`
```env
ENVIRONMENT=development
DEBUG=True
DATABASE_URI=mongodb://localhost:27017/smartaid_dev
FIREBASE_PROJECT_ID=smartaid-dev-project
CORS_ORIGINS=http://localhost:3000,*
LOG_LEVEL=DEBUG
```

### `.env.staging`
```env
ENVIRONMENT=staging
DEBUG=False
DATABASE_URI=${SECRET_MANAGER_MONGO_STAGING_URI}
FIREBASE_PROJECT_ID=smartaid-staging-project
CORS_ORIGINS=https://staging.smartaid.com
LOG_LEVEL=INFO
```

### `.env.production`
```env
ENVIRONMENT=production
DEBUG=False
DATABASE_URI=${SECRET_MANAGER_MONGO_PROD_URI}
FIREBASE_PROJECT_ID=smartaid-prod-project
CORS_ORIGINS=https://app.smartaid.com,https://admin.smartaid.com
LOG_LEVEL=WARNING
```

## 9. Secrets Management
Hardcoding secrets is strictly prohibited.
- **Google Secret Manager**: The central vault for all sensitive data (e.g., `DATABASE_URI`, `GEMINI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT`).
- **Runtime Injection**: Cloud Run automatically injects secrets from Secret Manager as environment variables at runtime.
- **Secret Rotation Strategy**: 
  - API keys and service accounts are automatically rotated every 90 days.
  - Emergency manual rotation playbooks are defined for suspected compromises.
