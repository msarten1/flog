"""Sesión HTTP con User-Agent propio, reintentos y pausa entre peticiones."""

from __future__ import annotations

import time
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from . import config


class Fetcher:
    """Pequeña envoltura de `requests.Session`.

    Se inyecta en cada fuente para poder sustituirla en los tests.
    """

    def __init__(self, delay: float = config.REQUEST_DELAY) -> None:
        self.delay = delay
        self._last: float = 0.0
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": config.USER_AGENT,
                "Accept-Language": "es-ES,es;q=0.9",
            }
        )
        retry = Retry(
            total=3,
            backoff_factor=1.5,
            status_forcelist=(429, 500, 502, 503, 504),
            allowed_methods=("GET", "POST"),
        )
        adapter = HTTPAdapter(max_retries=retry)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

    def _wait(self) -> None:
        elapsed = time.monotonic() - self._last
        if elapsed < self.delay:
            time.sleep(self.delay - elapsed)
        self._last = time.monotonic()

    def get(self, url: str, **kwargs: Any) -> str:
        self._wait()
        r = self.session.get(url, timeout=config.REQUEST_TIMEOUT, **kwargs)
        r.raise_for_status()
        return r.text

    def post(self, url: str, data: dict[str, Any] | None = None, **kwargs: Any) -> str:
        self._wait()
        r = self.session.post(url, data=data, timeout=config.REQUEST_TIMEOUT, **kwargs)
        r.raise_for_status()
        return r.text
