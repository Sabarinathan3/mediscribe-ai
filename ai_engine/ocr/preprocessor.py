import cv2
import numpy as np
from PIL import Image

class ImagePreprocessor:
    @staticmethod
    def enhance_for_ocr(image: Image.Image) -> Image.Image:
        """
        Enhance image for better OCR results. Includes binarization and denoising.
        """
        img_np = np.array(image.convert('RGB'))
        gray = cv2.cvtColor(img_np, cv2.COLOR_RGB2GRAY)
        
        # Denoising
        denoised = cv2.fastNlMeansDenoising(gray, h=10)
        
        # Adaptive Thresholding to handle shadows/lighting in photos
        binary = cv2.adaptiveThreshold(
            denoised, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
        )
        
        return Image.fromarray(binary)
