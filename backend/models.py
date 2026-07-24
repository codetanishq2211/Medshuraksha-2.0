from sqlalchemy import Column, Integer, String, Boolean
from database import Base

class Medicine(Base):
    __tablename__ = "medicines"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    manufacturer = Column(String)
    approved = Column(Boolean)
    side_effects = Column(String)
    avoid_in = Column(String)
    additional_info = Column(String)