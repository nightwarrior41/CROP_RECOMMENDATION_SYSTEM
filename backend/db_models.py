from sqlalchemy import Column, Integer, String, Float, DateTime
from database import Base
import datetime

class PredictionHistory(Base):
    __tablename__ = "prediction_history"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    crop_name = Column(String, index=True)
    temperature = Column(Float)
    humidity = Column(Float)
    rainfall = Column(Float)
    predicted_profit = Column(Float)
    predicted_yield = Column(Float)
    recommendations_json = Column(String) # Store recommended alternatives as JSON
