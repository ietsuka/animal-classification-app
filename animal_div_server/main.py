from fastapi import FastAPI, HTTPException
from tensorflow import keras;
from PIL import Image, UnidentifiedImageError
import numpy as np
import base64
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import io, os

app=FastAPI()
classes = ["monkey", "boar", "crow"]
image_size = 50
class ImageData(BaseModel):
    image: str

origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://your_local_ip",
    "*",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"greeting": "Hello World"}

@app.post("/images/")
def get_uploadfile(data: ImageData):
  try:
    image_data = data.image.split(",")[1] if "," in data.image else data.image
    UploadFile = base64.b64decode(image_data)
    image = Image.open(io.BytesIO(UploadFile))
    image = image.convert("RGB")
    image = image.resize((image_size, image_size))
    data = np.asarray(image)/255
    X = []
    X.append(data)
    X = np.array(X)

    if not os.path.exists('animal_cnn_aug.h5'):
      raise FileNotFoundError("animal_cnn_aug.h5 file not found!")

    model = keras.models.load_model('animal_cnn_aug.h5')

    result = model.predict([X])[0]
    predicted = result.argmax()
    percentage = int(result[predicted] * 100)
    return {
      "label": classes[predicted], 
      "percentage": percentage
    }
  except base64.binascii.Error as e:
        raise HTTPException(status_code=400, detail="Invalid base64 string")
  except UnidentifiedImageError as e:
      raise HTTPException(status_code=400, detail="Invalid image data")
  except Exception as e:
      raise HTTPException(status_code=500, detail=str(e))