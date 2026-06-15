# Agro Intelligence Backend

This directory contains the Python FastAPI backend and Machine Learning models supporting dynamic Crop Profit Predictions.

## Contents
1. `main.py`: Primary FastAPI application routing incoming prediction requests.
2. `database.py` & `db_models.py`: SQLAlchemy and SQLite database configuration storing historical predictions and system metrics. Note that switching this to PostgreSQL simply requires changing the `SQLALCHEMY_DATABASE_URL` string in `database.py`.
3. `train_profit_model.py`: Training script for Random Forest regression using generated feature arrays mapping to Crop variants. Run this to recreate `profit_model.pkl`.
4. `profit_model.pkl` and `crop_model.pkl`: Model weights generated post-training containing structure and serialized trees.
5. `requirements.txt`: Python package necessities.

## Deployment Setup
Ensure you operate within your virtual Python environment when executing any scripts here. 

### Preparing Models
If you want to re-train the models at any point, execute:
```bash
python3 train_profit_model.py
```
This script will construct synthetic profitability characteristics based on your `Crop_recommendation.csv` baseline to produce four distinct outcome variables. 

### Running API Base
Once requirements are locally satisfied, startup the REST framework locally for Flutter interoperability:
```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```
The FastAPI instance will attach itself locally to port `8000`.

### Database Interoperability
By default, the `main.py` process automatically connects and maintains schemas on the `agro_intelligence.db` file. Switch `SQLALCHEMY_DATABASE_URL` within `database.py` to point to a relational persistence layer once running in production.

## Dockerizing (Optional)
To deploy into a structured containerized system, author a simple `Dockerfile` containing:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```
