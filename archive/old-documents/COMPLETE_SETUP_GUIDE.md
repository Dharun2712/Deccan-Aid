# Complete Setup Guide: Deccan-Aid

This guide will walk you through setting up the entire Deccan-Aid system, including the Flutter frontend, FastAPI backend, and MongoDB Atlas database.

## Prerequisites
Before you begin, ensure you have the following installed:
1. **Flutter SDK** (v3.9.2+) - [Installation Guide](https://flutter.dev/docs/get-started/install)
2. **Python** (v3.8+) - [Installation Guide](https://www.python.org/downloads/)
3. **Git** - [Installation Guide](https://git-scm.com/downloads)
4. **Android Studio** or **VS Code** with Flutter and Dart plugins
5. A **MongoDB Atlas** account (Free tier is sufficient)

---

## 1. Database Setup (MongoDB Atlas)
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) and create a free account or log in.
2. Create a new Cluster (the free shared cluster is fine).
3. Under **Database Access**, create a new database user with a username and password. Remember these credentials.
4. Under **Network Access**, add `0.0.0.0/0` to allow access from anywhere (or restrict it to your IP for better security).
5. Go back to your Cluster and click **Connect**.
6. Choose **Connect your application**.
7. Copy the connection string. It will look something like this:
   `mongodb+srv://<username>:<password>@cluster0.mongodb.net/?retryWrites=true&w=majority`
8. Replace `<username>` and `<password>` with the credentials you created in Step 3.

---

## 2. Backend Setup (FastAPI)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Dharun2712/Deccan-Aid.git
   cd Deccan-Aid/backend
   ```

2. **Create and activate a virtual environment:**
   - **Windows:**
     ```bash
     python -m venv venv
     venv\Scripts\activate
     ```
   - **macOS/Linux:**
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements_fastapi.txt
   ```

4. **Configure Environment Variables:**
   Create a `.env` file in the `backend` directory and add the following:
   ```env
   MONGODB_URI=your_connection_string_here
   DB_NAME=deccan_ambulance
   JWT_SECRET=super_secret_key_please_change_in_production
   PORT=8000
   ```
   *Replace `your_connection_string_here` with the string from the Database Setup phase.*

5. **Initialize to seed the database (Optional):**
   ```bash
   python init_complete_database.py
   ```

6. **Start the server:**
   ```bash
   python app_fastapi.py
   ```
   The backend should now be running at `http://localhost:8000`.

---

## 3. Frontend Setup (Flutter)

1. **Navigate to the root directory:**
   Open a new terminal window and navigate to the project root.
   ```bash
   cd Deccan-Aid
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure the backend URL:**
   Open `lib/config/api_config.dart` and update the `baseUrl`.
   - If testing on an Android emulator: `http://10.0.2.2:8000`
   - If testing on a physical device, use your computer's local IP address: `http://192.168.x.x:8000` (ensure your phone and PC are on the same WiFi network).

4. **Run the application:**
   Connect a physical device via USB (with USB Debugging enabled) or start an emulator.
   ```bash
   flutter run
   ```

## Final Checks
- You should be able to see the login screen on your mobile device.
- The backend terminal should show successful connection logs to MongoDB.
- You can access the API documentation at `http://localhost:8000/docs`.
