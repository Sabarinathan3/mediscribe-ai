import os
import logging
from typing import List, Tuple, Dict, Any, Union
import numpy as np

try:
    import easyocr
    EASYOCR_AVAILABLE = True
except ImportError:
    EASYOCR_AVAILABLE = False

logger = logging.getLogger("mediscribe.ai_engine.ocr.easyocr_engine")


class EasyOCREngineError(Exception):
    """Exception raised for errors in the EasyOCR Engine."""
    pass


class EasyOCREngine:
    _readers: Dict[str, Any] = {}

    @classmethod
    def get_reader(cls, languages: List[str]) -> Any:
        """
        Retrieves or initializes an EasyOCR Reader instance for the specified languages.
        Caches the Reader in memory to avoid expensive re-initialization.
        """
        if not EASYOCR_AVAILABLE:
            raise EasyOCREngineError(
                "EasyOCR is not installed or available in this environment. "
                "Please run `pip install easyocr`."
            )

        cache_key = ",".join(sorted(languages))
        
        if cache_key not in cls._readers:
            try:
                use_gpu = os.getenv("USE_GPU", "false").lower() == "true"
                logger.info(f"Initializing EasyOCR Reader for languages: {languages} (gpu={use_gpu})")
                cls._readers[cache_key] = easyocr.Reader(languages, gpu=use_gpu)
            except Exception as e:
                raise EasyOCREngineError(f"Failed to initialize EasyOCR Reader: {str(e)}")
                
        return cls._readers[cache_key]

    @classmethod
    def read_text(
        cls, 
        image: Union[np.ndarray, str, bytes], 
        languages: List[str] = None
    ) -> List[Tuple[List[List[int]], str, float]]:
        """
        Performs OCR inference on an image and returns raw detections.
        Each detection is a tuple of:
          - Bounding Box: list of 4 coordinates [[x0, y0], [x1, y1], [x2, y2], [x3, y3]]
          - Text: parsed string
          - Confidence: float score in [0.0, 1.0]
        """
        if languages is None:
            languages = ["en"]

        try:
            reader = cls.get_reader(languages)
            
            # easyocr supports numpy arrays, bytes, or file paths directly
            raw_results = reader.readtext(image)
            
            formatted_results = []
            for bbox, text, confidence in raw_results:
                # Ensure coordinate values are standard python integers
                formatted_bbox = [[int(coord[0]), int(coord[1])] for coord in bbox]
                formatted_results.append((formatted_bbox, str(text).strip(), float(confidence)))
                
            return formatted_results
            
        except Exception as e:
            if not isinstance(e, EasyOCREngineError):
                raise EasyOCREngineError(f"OCR inference execution failed: {str(e)}")
            raise e
