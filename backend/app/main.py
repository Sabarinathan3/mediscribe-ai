"""
app/main.py — Entry point for `uvicorn app.main:app`

The real application lives in backend/main.py (one level up).
This shim adds the backend directory to sys.path so all
`from backend.*` imports resolve correctly, then re-exports
the FastAPI `app` object.

Run from S:\\mediscribeai\\MediScribe-AI\\backend\\:
    uvicorn app.main:app --reload
"""
import os
import sys

# Ensure the backend/ directory itself is on the path so that
# `from backend.config import settings` etc. resolve correctly.
# __file__ → .../backend/app/main.py  →  dirname → .../backend/app
# dirname again → .../backend  →  dirname again → .../MediScribe-AI (project root)
_app_dir = os.path.dirname(os.path.abspath(__file__))      # backend/app
_backend_dir = os.path.dirname(_app_dir)                   # backend
_project_root = os.path.dirname(_backend_dir)              # MediScribe-AI

for _p in (_backend_dir, _project_root):
    if _p not in sys.path:
        sys.path.insert(0, _p)

# Re-export the FastAPI application from the root main module.
# All routers, middleware, and exception handlers are registered there.
from main import app  # noqa: E402  (import after sys.path manipulation is intentional)

__all__ = ["app"]
