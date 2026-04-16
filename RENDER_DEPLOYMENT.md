# Deploying Agro Intelligence FastAPI Backend to Render

This guide outlines the steps to deploy your crop prediction backend to Render.com for free.

## 1. Prepare your GitHub Repository

Make sure your repository has a `backend` folder containing the following 3 files unconditionally:
- `main.py`
- `requirements.txt`
- `crop_model.pkl`

If you are using a unified repository for both your Flutter app and the backend, ensure this `backend/` folder is pushed to GitHub.

## 2. Set Up a New Web Service on Render

1. Go to [Render.com](https://render.com/) and create a free account or log in.
2. In the Render Dashboard, click **New +** and select **Web Service**.
3. Connect your GitHub account and select the repository containing your backend.

## 3. Configure the Render Web Service

Fill in the settings for your new service as follows:

- **Name**: `agro-intelligence-api` (or any unique name you prefer)
- **Runtime**: `Python 3`
- **Root Directory**: `backend` *(This is critical: it tells Render that `main.py` and `requirements.txt` are inside the `backend` folder)*
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

## 4. Deploy

1. Make sure you select the **Free Instance Type** ($0/month).
2. Click **Create Web Service**.

Wait a few minutes. Render will clone your repository, run the pip install build command, and start the `uvicorn` server to fire off your FastAPI endpoints.

> **Note**: Free instances on Render spin down automatically after periods of inactivity. If you haven't used the prediction feature in a while, your very first request may take around 50 seconds as the server wakes back up.

## 5. Update the Flutter App

Once the deployment in Render says **"Live"**, copy the `onrender.com` URL provided near the top left of your dashboard (for example, `https://agro-intelligence-api-abc.onrender.com`).

Open your Flutter project, edit `lib/services/crop_prediction_service.dart`, and replace the `baseUrl` variable:

```dart
// Change this:
static String baseUrl = 'http://10.0.2.2:8000';

// To your new production URL:
static String baseUrl = 'https://agro-intelligence-api-abc.onrender.com';
```

## 6. Real-world Testing

Restart your Flutter application (`flutter run`), go to the Crop Prediction screen, type in new environmental inputs, and verify that your cloud-hosted Machine Learning model is accurately responding.
