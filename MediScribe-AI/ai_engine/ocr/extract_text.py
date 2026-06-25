import logging
from typing import List, Dict, Any, Tuple, Union
from PIL import Image

from ai_engine.ocr.image_preprocessor import ImagePreprocessor
from ai_engine.ocr.easyocr_engine import EasyOCREngine

logger = logging.getLogger("mediscribe.ai_engine.ocr.extract_text")


class TextExtractor:
    @staticmethod
    def group_into_lines(
        ocr_results: List[Tuple[List[List[int]], str, float]],
        y_tolerance_ratio: float = 0.5
    ) -> List[List[Tuple[List[List[int]], str, float]]]:
        """
        Groups bounding boxes into layout-aware lines based on vertical overlap.
        Sorts lines top-to-bottom and words in a line left-to-right.
        """
        if not ocr_results:
            return []

        # Sort primarily by top Y-coordinate
        sorted_detections = sorted(ocr_results, key=lambda x: x[0][0][1])
        
        lines: List[List[Tuple[List[List[int]], str, float]]] = []
        
        for det in sorted_detections:
            bbox, text, conf = det
            y_min = min(pt[1] for pt in bbox)
            y_max = max(pt[1] for pt in bbox)
            h = y_max - y_min
            
            placed = False
            for line in lines:
                line_y_mins = [min(pt[1] for pt in item[0]) for item in line]
                line_y_maxs = [max(pt[1] for pt in item[0]) for item in line]
                avg_h = sum(max(pt[1] for pt in item[0]) - min(pt[1] for pt in item[0]) for item in line) / len(line)
                
                line_y_min = min(line_y_mins)
                line_y_max = max(line_y_maxs)
                
                det_center_y = (y_min + y_max) / 2
                line_center_y = (line_y_min + line_y_max) / 2
                
                if abs(det_center_y - line_center_y) < (avg_h * y_tolerance_ratio):
                    line.append(det)
                    placed = True
                    break
            
            if not placed:
                lines.append([det])
                
        # Sort words inside each line left-to-right
        sorted_lines = []
        for line in lines:
            sorted_line = sorted(line, key=lambda x: x[0][0][0])
            sorted_lines.append(sorted_line)
            
        # Re-sort lines top-to-bottom
        sorted_lines = sorted(
            sorted_lines, 
            key=lambda line: sum((min(pt[1] for pt in item[0]) + max(pt[1] for pt in item[0])) / 2 for item in line) / len(line)
        )
        
        return sorted_lines

    @classmethod
    def extract_text(
        cls, 
        image_input: Union[str, bytes, Image.Image],
        languages: List[str] = None
    ) -> Dict[str, Any]:
        """
        Processes a prescription image and returns the layout-assembled raw text
        and the average OCR confidence score.
        
        Input:
          - image_input: str (file path), bytes (raw image bytes), or PIL Image
          
        Output:
          {
            "text": "...",
            "confidence": 0.95
          }
        """
        # Step 1: Preprocess and optimize the image using OpenCV
        try:
            enhanced_img = ImagePreprocessor.preprocess(image_input)
        except Exception as e:
            logger.error(f"Image preprocessing failed: {str(e)}")
            # Fallback to loading the raw image without modifications
            try:
                enhanced_img = ImagePreprocessor.load_image(image_input)
            except Exception as load_err:
                return {
                    "text": "",
                    "confidence": 0.0,
                    "error": f"Failed to load image: {str(load_err)}"
                }

        # Step 2: Run EasyOCR inference
        try:
            detections = EasyOCREngine.read_text(enhanced_img, languages=languages)
        except Exception as e:
            logger.error(f"EasyOCR inference failed: {str(e)}")
            return {
                "text": "",
                "confidence": 0.0,
                "error": f"OCR processing failed: {str(e)}"
            }

        # Step 3: Layout-Aware Line Grouping
        grouped_lines = cls.group_into_lines(detections)
        
        reconstructed_lines = []
        for line in grouped_lines:
            line_text = " ".join(item[1] for item in line)
            reconstructed_lines.append(line_text)
            
        full_raw_text = "\n".join(reconstructed_lines)
        
        # Calculate overall confidence score
        confidence_scores = [det[2] for det in detections]
        avg_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0.0

        return {
            "text": full_raw_text,
            "confidence": round(avg_confidence, 2)
        }
