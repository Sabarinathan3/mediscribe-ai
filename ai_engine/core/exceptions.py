class MediScribeError(Exception):
    """Base exception for all MediScribe AI errors."""
    pass

class OCRError(MediScribeError):
    """Raised when OCR fails or confidence is too low."""
    pass

class NLPProcessingError(MediScribeError):
    """Raised when parsing or entity extraction fails."""
    pass

class SafetyValidationError(MediScribeError):
    """Raised when drug safety checks fail critically."""
    pass
