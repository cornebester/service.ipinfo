# Local , non serverless script for basic api use, test
# https://github.com/ipinfo/python


import os
import socket
import logging
from flask import Flask, request, jsonify
from markupsafe import escape, Markup
import redis
from redis.retry import Retry
from redis.exceptions import TimeoutError, ConnectionError
from redis.backoff import ExponentialBackoff
import ipinfo
# from logging_lib import logging_lib

# Main logger
logger = logging.getLogger(__name__)


log_level = os.getenv("LOG_LEVEL", "INFO")
logger.setLevel(log_level)

logger.warning("ROOT LOG_LEVEL set to: %s", log_level)

application = Flask(__name__)
application.logger.setLevel(log_level)

# log = logging.getLogger('werkzeug')
# log.setLevel(log_level)

access_token = os.getenv("IPINFO_ACCESS_TOKEN")
redis_host = os.getenv("REDIS_HOST", "localhost")


def ipinfo_get_details():
    """ """
    ipinfo_obj = ipinfo.getHandler(access_token)
    try:
        result = ipinfo_obj.getDetails()
        logger.info("ipinfo lookup successful. Got %s", result.ip)
        return result.details
    except Exception:
        logger.exception("ipinfo lookup failed")
        return {}


response = ipinfo_get_details()


# Connect to Redis
# redis = Redis(host=redis_host, db=0, socket_connect_timeout=2, socket_timeout=2)


def redis_handler():
    """ """
    try:
        application.logger.info("Connecting to redis...")
        redis_connection = redis.Redis(
            host=redis_host,
            db=0,
            socket_connect_timeout=2,
            socket_timeout=2,
            retry=Retry(ExponentialBackoff(cap=2, base=1), 2),
            retry_on_error=[ConnectionError, TimeoutError, ConnectionResetError],
            health_check_interval=1,
        )
        if redis_connection.ping():
            application.logger.info("Connected to redis")
        return redis_connection
    except TimeoutError as r:
        application.logger.error("Redis Connection failed: %s", r)


redis_conn_obj = redis_handler()

html = (
    "<h3>IPInfo service</h3>"
    "<b>Hostname, machine name, container name:</b> {hostname}<br/>"
    "<b>Number of visits:</b> {visits}<br/>"
    "<b>Outbound: External IP:</b> {ext_ip}<br/>"
    "<b>Inbound: L4 localhost/previous hop/LB NAT:</b> {remote_addr}<br/>"
    "<b>Inbound: L7 X-Forwarded-For HTTP header:</b> {header_xforwardfor}<br/>"
    "<b>Pod log level:</b> {log_level}<br/>"
)

html_health_checkl = "liveness check - pass"
html_health_checkr = "readiness check - pass"

application = Flask(__name__)

# below set flask logging to match level if not run via gunicorn
if __name__ != "__main__":
    gunicorn_logger = logging.getLogger("gunicorn.error")
    application.logger.handlers = gunicorn_logger.handlers
    application.logger.setLevel(log_level)


@application.route("/")
def root():
    """ """
    try:
        if redis_conn_obj is not None and redis_conn_obj.ping():
            # redis.ping()
            # logger.debug('redis is alive')
            visits = redis_conn_obj.incr("counter")
            application.logger.debug("redis: incremented visits key")
            if dict(request.headers).get("X-Forwarded-For") is None:
                redis_conn_obj.incr("ip_" + str(request.remote_addr))
            else:
                redis_conn_obj.incr(
                    "ip_" + str(dict(request.headers).get("X-Forwarded-For"))
                )
        else:
            visits = "<i>cannot connect to Redis, counter disabled</i>"
        ipinfo_response = ipinfo_get_details()
        application.logger.debug("request headers: %s", request.headers)
        application.logger.debug(
            "request xforfor: %s", str(dict(request.headers).get("X-Forwarded-For"))
        )
        application.logger.debug("request remote: %s", request.remote_addr)
        return html.format(
            hostname=escape(socket.gethostname()),
            visits=visits,
            ext_ip=escape(ipinfo_response["ip"]),
            remote_addr=escape(request.remote_addr or ""),
            log_level=escape(log_level),
            header_xforwardfor=escape(
                dict(request.headers).get("X-Forwarded-For") or ""
            ),
        )
    except TimeoutError as r:
        application.logger.error("Redis Timeout Error: %s", r)
        return html.format(
            hostname=escape(socket.gethostname()),
            visits="<i>Redis Timeout</i>",
            ext_ip=escape(response["ip"]),
            remote_addr=escape(request.remote_addr or ""),
            log_level=escape(log_level),
            header_xforwardfor=escape(
                dict(request.headers).get("X-Forwarded-For") or ""
            ),
        )

    except Exception as e:
        # Handle any other unexpected errors
        application.logger.exception(e)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500


@application.route("/healthr")
def readiness():
    """
    Basic readiness check - check redis connection.
    Redis used for stats
    """
    try:
        application.logger.info("Checking if redis alive")
        if redis_conn_obj is not None and redis_conn_obj.ping():
            # read = redis_conn_obj.get("counter")
            # check = redis_conn_obj.ping()
            return html_health_checkr
        else:
            application.logger.error("redis not available")
            return "readiness check - fail", 500
    except TimeoutError as r:
        application.logger.error("Redis Timeout Error: %s", r)

    except Exception as e:
        # Handle any other unexpected errors
        application.logger.exception(e)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500


@application.route("/healthl")
def liveness():
    """
    Basic liveness check 
    """
    try:
        return html_health_checkl

    except Exception as e:
        # Handle any other unexpected errors
        application.logger.exception(e)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500


@application.route("/api")
def api():
    """ """
    application.logger.debug("hit api")
    try:
        x = ipinfo_get_details()
        # visits = redis.incr("counter")
        return dict(x)

    except Exception as e:
        # Handle any other unexpected errors
        application.logger.exception(e)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500


@application.route("/stats")
def stats():
    """ """
    cursor = 0
    try:
        if redis_conn_obj is not None and redis_conn_obj.ping():
            cursor, keys = redis_conn_obj.scan(cursor=cursor, match="ip_*", count=1000)
            all_keys = redis_conn_obj.keys("ip_*")
            application.logger.debug("redis scanned keys: %s", keys)
            application.logger.debug("redis keys: %s", all_keys)
            callers = []
            count = {}
            for e in keys:
                e.decode("utf-8")
                callers.append(e.decode("utf-8"))
            for ip in callers:
                hits = redis_conn_obj.get(ip).decode("utf-8")
                count[ip] = int(hits)
            top = sorted(count, key=count.get, reverse=True)
            top5 = {}
            for ip in top[:5]:
                top5[ip] = int(redis_conn_obj.get(ip).decode("utf-8"))
            return top5
        else:
            return "<i>No statistics. Redis is unavailable</i>", 500
    except TimeoutError as r:
        application.logger.error("Redis Timeout Error: %s", r)
    
    except Exception as e:
        # Handle any other unexpected errors
        application.logger.exception(e)
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500


if __name__ == "__main__":
    if log_level == "DEBUG":
        application.debug = True
    application.run(host="0.0.0.0", port=81)
