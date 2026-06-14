# Flask Backend for Smart Ambulance Authentication

## Setup Instructions

### 1. Install Python Dependencies

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # On Windows
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update with your values:

```bash
copy .env.example .env
```

**IMPORTANT:** Change the `JWT_SECRET` value in production!

### 3. Run the Development Server

```bash
python app.py
```

The server will start on `http://localhost:5000`

### 4. Test the API

Health check:
```bash
curl http://localhost:5000/api/health
```

## API Endpoints

- `POST /api/login/client` - Client login (email/phone + password)
- `POST /api/login/driver` - Driver login (driver_id + password)
- `POST /api/login/admin` - Admin login (hospital_code + password)
- `POST /api/register/client` - Client registration
- `GET /api/health` - Health check

## MongoDB Setup

See the main SETUP.md for MongoDB collection structure and sample data.

## Production Deployment

For production:
1. Set strong `JWT_SECRET` environment variable
2. Use HTTPS (nginx + Let's Encrypt)
3. Run with gunicorn: `gunicorn -w 4 -b 0.0.0.0:5000 app:app`
4. Implement rate limiting and account lockout
5. Never commit `.env` file to version control
