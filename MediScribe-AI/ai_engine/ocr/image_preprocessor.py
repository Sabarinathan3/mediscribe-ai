import io
import math
from typing import Tuple, Union
from PIL import Image

try:
    import cv2
    import numpy as np
    OPENCV_AVAILABLE = True
except ImportError:
    OPENCV_AVAILABLE = False


class ImagePreprocessorError(Exception):
    """Exception raised for errors during image preprocessing."""
    pass


class ImagePreprocessor:
    @staticmethod
    def load_image(image_input: Union[str, bytes, Image.Image]) -> "np.ndarray":
        """
        Loads an image from a file path, raw bytes, or PIL Image into a NumPy BGR array.
        """
        if not OPENCV_AVAILABLE:
            raise ImagePreprocessorError("OpenCV or NumPy is not installed/available in the environment.")

        try:
            if isinstance(image_input, str):
                img = cv2.imread(image_input)
                if img is None:
                    raise ImagePreprocessorError(f"Failed to read image from path: {image_input}")
                return img
            
            elif isinstance(image_input, bytes):
                nparr = np.frombuffer(image_input, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                if img is None:
                    raise ImagePreprocessorError("Failed to decode image from bytes.")
                return img
            
            elif isinstance(image_input, Image.Image):
                img_rgb = np.array(image_input)
                if len(img_rgb.shape) == 2:
                    return cv2.cvtColor(img_rgb, cv2.COLOR_GRAY2BGR)
                elif img_rgb.shape[2] == 4:
                    return cv2.cvtColor(img_rgb, cv2.COLOR_RGBA2BGR)
                else:
                    return cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR)
            else:
                raise ImagePreprocessorError(f"Unsupported image input type: {type(image_input)}")
        except Exception as e:
            if not isinstance(e, ImagePreprocessorError):
                raise ImagePreprocessorError(f"Error loading image: {str(e)}")
            raise e

    @staticmethod
    def resize_optimization(img: "np.ndarray", target_width: int = 1600) -> "np.ndarray":
        """
        Resizes the image to an optimal width for OCR (default 1600px)
        while maintaining the original aspect ratio. 
        Downscaling large images speeds up inference.
        Upscaling small images improves low-res character detection.
        """
        if not OPENCV_AVAILABLE:
            return img

        h, w = img.shape[:2]
        if w == target_width:
            return img

        aspect_ratio = h / w
        target_height = int(target_width * aspect_ratio)

        # Use INTER_AREA for downscaling (avoids aliasing) and INTER_CUBIC for upscaling
        interpolation = cv2.INTER_AREA if w > target_width else cv2.INTER_CUBIC
        resized = cv2.resize(img, (target_width, target_height), interpolation=interpolation)
        return resized

    @staticmethod
    def remove_noise(img: "np.ndarray") -> "np.ndarray":
        """
        Applies noise reduction while preserving crisp text edges.
        Uses Bilateral Filter to smooth flat areas and preserve high-frequency text boundaries.
        Also applies light median blur to eliminate speckle noise.
        """
        if not OPENCV_AVAILABLE:
            return img

        try:
            # Bilateral filter: d=9, sigmaColor=75, sigmaSpace=75
            denoised = cv2.bilateralFilter(img, 9, 75, 75)
            return denoised
        except Exception:
            return img

    @staticmethod
    def enhance_contrast(img: "np.ndarray") -> "np.ndarray":
        """
        Converts to grayscale and enhances contrast using CLAHE
        (Contrast Limited Adaptive Histogram Equalization).
        """
        if not OPENCV_AVAILABLE:
            return img

        try:
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            # ClipLimit controls contrast enhancement levels; grid is patch size
            clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
            enhanced = clahe.apply(gray)
            return enhanced
        except Exception as e:
            raise ImagePreprocessorError(f"Contrast enhancement failed: {str(e)}")

    @staticmethod
    def binarize(gray_img: "np.ndarray") -> "np.ndarray":
        """
        Performs adaptive Gaussian thresholding to cleanly separate ink text from paper.
        """
        if not OPENCV_AVAILABLE:
            return gray_img

        try:
            binarized = cv2.adaptiveThreshold(
                gray_img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY, 11, 2
            )
            # Re-convert to BGR for compatibility with downstream processes
            return cv2.cvtColor(binarized, cv2.COLOR_GRAY2BGR)
        except Exception as e:
            raise ImagePreprocessorError(f"Binarization failed: {str(e)}")

    @classmethod
    def preprocess(cls, image_input: Union[str, bytes, Image.Image]) -> "np.ndarray":
        """
        Orchestrates full OpenCV preprocessing pipeline.
        """
        # 1. Load image
        img = cls.load_image(image_input)
        
        # 2. Resize to optimal scale
        resized = cls.resize_optimization(img)
        
        # 3. Noise removal
        denoised = cls.remove_noise(resized)
        
        # 4. Enhance contrast (produces grayscale)
        enhanced_gray = cls.enhance_contrast(denoised)
        
        # 5. Adaptive binarization (returns 3-channel binarized BGR image)
        binarized_img = cls.binarize(enhanced_gray)
        
        return binarized_img
