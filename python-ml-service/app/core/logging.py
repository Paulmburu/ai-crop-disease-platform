"""structlog setup: readable coloured logs locally, JSON lines in production.

Call configure_logging() once at startup, then everywhere:
    log = structlog.get_logger(__name__)
    log.info("prediction_made", class_name="Potato___healthy", ms=41.2)
"""

import logging

import structlog


def configure_logging(level: str = "INFO", json_logs: bool = False) -> None:
    renderer = structlog.processors.JSONRenderer() if json_logs else structlog.dev.ConsoleRenderer()
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,  # carries request_id into every line
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.format_exc_info,
            renderer,
        ],
        wrapper_class=structlog.make_filtering_bound_logger(logging.getLevelName(level.upper())),
        cache_logger_on_first_use=True,
    )
