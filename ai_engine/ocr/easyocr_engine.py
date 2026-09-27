import easyocr
import numpy as np
from PIL import Image
from typing import Tuple, List

class EasyOCREngine:
    def __init__(self, languages: List[str] = ['en']):
        # Initialize easyocr reader. Note: it downloads models on first run if not found
        self.reader = easyocr.Reader(languages, gpu=False) # Use CPU for low-resource assumption
        
    def extract_text(self, image: Image.Image) -> Tuple[str, float]:
        """
        Extracts text from an image using EasyOCR.
        Returns the extracted text and the average confidence score.
        """
        # Convert PIL Image to OpenCV format (numpy array)
        img_np = np.array(image.convert('RGB'))
        # Read text
        results = self.reader.readtext(img_np)
        
        if not results:
            return "", 0.0
            
        texts = [res[1] for res in results]
        confidences = [res[2] for res in results]
        
        full_text = " ".join(texts)
        avg_confidence = sum(confidences) / len(confidences)
        
        return full_text, avg_confidence
