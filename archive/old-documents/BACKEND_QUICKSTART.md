# Backend Quickstart: Deccan-Aid

For developers looking to run or test the FastAPI backend quickly, follow these simplified steps.

## Requirements
- Python 3.8+
- Active MongoDB connection string

## Quick Setup Steps

### 1. Environment Preparation
Navigate into the backend directory and set up an isolated Python environment:

```bash
cd backend
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Mac/Linux)
source venv/bin/activate
```

### 2. Install Packages
Install FastAPI, Uvicorn, Motor (or PyMongo), Socket.IO, and other required libraries.

```bash
pip install -r requirements_fastapi.txt
```

### 3. Environment Variable Config
Ensure the server can talk to the database by creating the `.env` file in the `backend/` folder.

```env
MONGODB_URI=mongodb+srv://<user>:<password>@<cluster-url>/
DB_NAME=deccan_ambulance
JWT_SECRET=dev_secret_key_123
PORT=8000
```

### 4. Database Seeding (Optional)
If you want to test the API with pre-populated dummy users (drivers and hospitals):
```bash
python init_complete_database.py
```

### 5. Running the Application
The `app_fastapi.py` typically wraps both the FastAPI instance and the Socket.IO ASGI application. Run it using Uvicorn directly for hot-reloading in development:

```bash
uvicorn app_fastapi:socket_app --host 0.0.0.0 --port 8000 --reload
```
*(Note: Use `socket_app` or whatever the ASGI wrapped instance is named in `app_fastapi.py`)*

## Exploring the API
Once running, FastAPI automatically generates interactive documentation. Open your browser and navigate to:
- **Swagger UI:** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`

You can use the Swagger UI to create mock POST requests, including firing test `SOS` events or updating driver locations.
