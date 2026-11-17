# Deploying AWS Guardian Backend to Render 🚀

This backend is now **100% production-ready** for hosting on [Render](https://render.com).

It includes:
- **Gunicorn** WSGI HTTP Server with multi-worker concurrency.
- **WhiteNoise** for serving static assets (Django Admin CSS/JS) with compression and caching.
- **PostgreSQL Database Support** via `DATABASE_URL` (compatible with Render Managed Postgres, Supabase, Neon, AWS RDS, etc.).
- **Automatic Build Script (`build.sh`)** that installs requirements, collects static files, and executes migrations automatically on each deployment.
- **Render Blueprint (`render.yaml`)** for 1-click automated provisioning of the Database and Web Service.
- **Reverse Proxy & SSL Support** configured for Render load balancers (`SECURE_PROXY_SSL_HEADER`, `CSRF_TRUSTED_ORIGINS`).
- **Zero-Secret Git Workflow** allowing Firebase credentials to be securely supplied via environment variable (`FIREBASE_CREDENTIALS_JSON`).

---

## Method 1: Automated Deployment via Blueprint (Recommended - 1 Click)

Render Blueprints read the included `render.yaml` file to provision both your PostgreSQL database and Django web service in one step:

1. Push your repository to **GitHub** or **GitLab**.
2. Log in to [dashboard.render.com](https://dashboard.render.com/).
3. Click **"New +"** (top right) $\rightarrow$ **"Blueprint"**.
4. Connect your GitHub repository.
5. Render will detect `render.yaml` and show:
   - **Database**: `aws-guardian-db` (Free PostgreSQL)
   - **Web Service**: `aws-guardian-backend` (Free Python Web Service)
6. Click **"Apply"**.
7. Render will automatically build the service, run migrations, collect static assets, and assign you a live HTTPS public URL:
   ```
   https://aws-guardian-backend-xxxx.onrender.com
   ```

---

## Method 2: Manual Web Service Setup (Step-by-Step)

If you prefer to set up services manually via the Render UI:

### Step 1: Create PostgreSQL Database
1. In Render Dashboard, click **"New +"** $\rightarrow$ **"PostgreSQL"**.
2. Name: `aws-guardian-db`
3. Database: `aws_guardian`
4. User: `guardian_user`
5. Region: Choose your preferred region (e.g., `Oregon (US West)` or `Singapore`).
6. Plan: **Free**.
7. Click **"Create Database"**.
8. Once created, copy the **"Internal Database URL"** (if Web Service is in same region) or **"External Database URL"**.

### Step 2: Create Web Service
1. Click **"New +"** $\rightarrow$ **"Web Service"**.
2. Connect your GitHub repository.
3. Configure the service settings:
   - **Name**: `aws-guardian-backend`
   - **Region**: Same region as your database
   - **Branch**: `main` (or your branch)
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `./build.sh`
   - **Start Command**: `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 3 --threads 2`
   - **Plan**: **Free**

### Step 3: Add Environment Variables
In the **Environment Variables** section of the Web Service, add:

| Key | Value / Description |
|---|---|
| `PYTHON_VERSION` | `3.12.0` |
| `DEBUG` | `False` |
| `DJANGO_SECRET_KEY` | *(Generate any long random string or leave Render to auto-generate)* |
| `JWT_SECRET_KEY` | *(Generate any long random string)* |
| `DATABASE_URL` | *(Paste the PostgreSQL connection string from Step 1)* |
| `CORS_ALLOW_ALL_ORIGINS` | `True` |
| `MOCK_FCM` | `True` *(or paste `FIREBASE_CREDENTIALS_JSON` below)* |
| `ALLOWED_HOSTS` | `.onrender.com,localhost,127.0.0.1` |
| `MORNING_SCAN_TIME` | `09:00` |
| `EVENING_SCAN_TIME` | `18:00` |
| `SCAN_TIMEZONE` | `Asia/Kolkata` |

*(Optional)* If you want real Firebase Push Notifications in production:
- Add `FIREBASE_CREDENTIALS_JSON` and paste the entire JSON content of your `firebase-service-account.json`.
- Set `MOCK_FCM` to `False`.

4. Click **"Deploy Web Service"**.

---

## Step 4: Verify Deployment

Once Render displays **"Live"**, open:
```
https://<your-service-name>.onrender.com/api/health/
```

Expected JSON response:
```json
{
  "status": "healthy",
  "service": "AWS Guardian Backend API",
  "version": "1.0.0"
}
```

You can access the Django Admin portal at:
```
https://<your-service-name>.onrender.com/admin/
```

### To create an Admin Superuser on Render:
1. In your Render Web Service dashboard, go to the **"Shell"** tab.
2. Run:
   ```bash
   python manage.py createsuperuser
   ```
3. Enter username, email, and password.

---

## Step 5: Connect Mobile App & Admin Console

### 1. Flutter Mobile App
In `mobile/lib/core/constants/api_constants.dart`:
```dart
// Set your live Render URL:
static const String renderBaseUrl = 'https://<your-service-name>.onrender.com/api';

// Point defaultBaseUrl to renderBaseUrl:
static String get defaultBaseUrl => renderBaseUrl;
```

### 2. Admin Web Panel
In `admin/.env`:
```env
VITE_API_BASE_URL=https://<your-service-name>.onrender.com/api
```

---

## Important Render Free Tier Note
On Render's Free tier, web services spin down after 15 minutes of inactivity. When a new request arrives, it takes ~30–50 seconds to wake up (cold start). For zero cold starts in 24/7 production, you can upgrade to Render's **Starter** tier ($7/month) or use a free uptime monitor (like UptimeRobot) to ping `/api/health/` every 10 minutes.
