# AWS Guardian — Deployment Guide

## Prerequisites
- Python 3.12+ (or Docker & Docker Compose)
- Flutter SDK 3.22+
- PostgreSQL (or SQLite for local dev)

---

## 1. Running with Docker Compose (Fastest)

```bash
# 1. Clone repository
git clone https://github.com/your-org/aws_guardian.git
cd aws_guardian

# 2. Configure environment
cp .env.example .env

# 3. Start PostgreSQL and Django Backend
docker compose up --build -d

# 4. View logs
docker compose logs -f backend
```

The API will be available at `http://localhost:8000/api/`.

---

## 2. Running Backend Manually (Local Python)

```bash
cd backend

# Create virtual environment
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Run tests
python manage.py test

# Start development server
python manage.py runserver 0.0.0.0:8000
```

---

## 3. Running Flutter Mobile App

```bash
cd mobile

# Install Flutter dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run unit and widget tests
flutter test

# Run on connected device or emulator
flutter run

# Build release APK for Android
flutter build apk --release
```

---

## 4. Configuring Mobile App for Physical Device or Emulator

- **Android Emulator**: Uses `http://10.0.2.2:8000/api` by default.
- **iOS Simulator**: Uses `http://127.0.0.1:8000/api` by default.
- **Physical Device**: Go to **More > Settings > Appearance & API Config**, and set Base API URL to your computer's local LAN IP (e.g. `http://192.168.1.100:8000/api`).
