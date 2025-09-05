import os
import logging
from datetime import datetime
from pythonjsonlogger import jsonlogger
from logging.config import dictConfig

log_level = os.getenv("LOG_LEVEL", "INFO")

logger = logging.getLogger(__name__)

logger.warning('Logging_lib LOG_LEVEL set to: {0}'.format(
    logger.getEffectiveLevel))


class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super(CustomJsonFormatter, self).add_fields(
            log_record, record, message_dict)
        if not log_record.get('logtime'):
            # this doesn't use record.created, so it is slightly off
            now = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            log_record['logtime'] = now
        if log_record.get('level'):
            log_record['level'] = log_record['level'].upper()
        else:
            log_record['level'] = record.levelname


dictConfig({
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '%(asctime)s - [%(levelname)s] %(name)s [%(module)s.%(funcName)s:%(lineno)d]: %(message)s',
            'datefmt': '%Y-%m-%d %H:%M:%S',
        },
        "json": {
            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "format": "%(asctime)s %(name)s %(levelname)s:%(message)s"
        },
        "json_custom": {
            "()": CustomJsonFormatter,
            "format": "%(logtime)s %(level)s %(name)s %(message)s"
        }
    },
    'handlers': {
        'default': {
            'level': log_level,
            'class': 'logging.StreamHandler',
            'formatter': 'standard',
        },
        "json": {
            'level': log_level,
            "class": "logging.StreamHandler",
            "formatter": "json"
        },
        "json_custom": {
            'level': log_level,
            "class": "logging.StreamHandler",
            "formatter": "json_custom"
        }
    },
    'loggers': {
        '__main__': {
            'handlers': ['json_custom'],
            'level': log_level,
            'propagate': False,
        },
        'gunicorn.error': {
            'handlers': ['json_custom'],
            'level': log_level,
            'propagate': False,
        },
        'gunicorn.access': {
            'handlers': ['json_custom'],
            'level': log_level,
            'propagate': False,
        },
        'werkzeug': {
            'handlers': ['json_custom'],
            'level': log_level,
            'propagate': False,
        },
    },
    'root': {
        'level': log_level,
        'handlers': ['json_custom']
    }
})

# Main logger
# logger = logging.getLogger(__name__)
