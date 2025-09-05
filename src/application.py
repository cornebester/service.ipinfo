# Local , non serverless script for basic api use, test
# https://github.com/ipinfo/python

import ipinfo
from flask import Flask, request
from redis import Redis, RedisError
import sys
import os
import socket
import requests
import logging
from logging_lib import logging_lib

# Main logger
logger = logging.getLogger(__name__)

log_level = os.getenv("LOG_LEVEL", "INFO")
logger.setLevel(log_level)

logger.warning('ROOT LOG_LEVEL set to: {0}'.format(log_level))

# log = logging.getLogger('werkzeug')
# log.setLevel(log_level)

access_token = os.getenv("IPINFO_ACCESS_TOKEN")
handler = ipinfo.getHandler(access_token)

redis_host = os.getenv("REDIS_HOST", "redis")


def ipinfo():
    try:
        details = handler.getDetails()
    except requests.exceptions.HTTPError as e:
        logger.exception(
            'ipinfo lookup failed. Exception thrown <{0}>'.format(e))
        return e
    else:
        logger.info('ipinfo lookup successful. Got {0}'.format(details.ip))
        return details

#response = ipinfo()


# Connect to Redis
# redis = Redis(host=redis_host, db=0, socket_connect_timeout=2, socket_timeout=2)


def redis_handler():
    try:
        logger.info('Connecting to redis...')
        redis = Redis(host=redis_host, db=0,
                      socket_connect_timeout=2, socket_timeout=2)
        redis.ping()
    except RedisError as r:
        logger.exception('RedisException: {}'.format(r))
    return redis


redis = redis_handler()

html = "<h3>IPInfo service</h3>" \
    "<b>Hostname, machine name, container name:</b> {hostname}<br/>" \
    "<b>Number of visits:</b> {visits}<br/>" \
    "<b>Outbound: External IP:</b> {ext_ip}<br/>" \
    "<b>Inbound: L4 localhost/previous hop/LB NAT:</b> {remote_addr}<br/>" \
    "<b>Inbound: L7 X-Forwarded-For HTTP header:</b> {header_xforwardfor}<br/>" \
    "<b>Pod log level:</b> {log_level}<br/>"

html_health_checkl = "liveness check - pass"
html_health_checkr = "readiness check - pass"

application = Flask(__name__)

# below set flask logging to match level if not run via gunicorn
if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    application.logger.handlers = gunicorn_logger.handlers
    application.logger.setLevel(log_level)


@application.route("/")
def root():
    try:
        if redis.ping():
            # logger.debug('redis is alive')
            visits = redis.incr("counter")
            logger.debug('redis: incremented visits key')
            if dict(request.headers).get('X-Forwarded-For') == None:
                redis.incr('ip_' + request.remote_addr)
            else:
                redis.incr(
                    'ip_' + str(dict(request.headers).get('X-Forwarded-For')))
        ipinfo_response = ipinfo()
        logger.debug('request headers: {}'.format(request.headers))
        logger.debug('request xforfor: {}'.format(str(dict(request.headers).get('X-Forwarded-For'))))
        logger.debug('request remote: {}'.format(request.remote_addr))
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    return html.format(hostname=socket.gethostname(), visits=visits, ext_ip=ipinfo_response.ip, remote_addr=request.remote_addr, log_level=log_level, header_xforwardfor=dict(request.headers).get('X-Forwarded-For'))


@application.route("/healthr")
def readiness():
    try:
        read = redis.get("counter")
        check = redis.ping()
        return html_health_checkr

    except RedisError as r:
        visits = "<i>cannot connect to Redis, counter disabled</i>"
        logger.exception('Other error: {}'.format(r))

    except Exception as e:
        logger.exception('Other error: {}'.format(e))

    return "error - readiness fail", 500
    # return render_template("500.html"), 500


@application.route("/healthl")
def liveness():
    try:
        return html_health_checkl

    except Exception as e:
        logger.exception('Other error: {}'.format(e))

    return "error - liveness fail", 500
    # return render_template("500.html"), 500


@application.route("/api")
def api():
    try:
        response = ipinfo()
        visits = redis.incr("counter")

    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    return dict(response.details)

@application.route("/stats")
def stats():
    try:
        byte = redis.scan(int = 0, match='ip_*', count=1000)[1]
        all_keys = redis.keys('ip_*')
        logger.debug('redis scanned keys: {}'.format(byte))
        logger.debug('redis keys: {}'.format(all_keys))
        callers = []
        count = {}
        for e in byte:
            e.decode("utf-8")
            callers.append(e.decode("utf-8"))
        for ip in callers:
            hits = redis.get(ip).decode("utf-8")
            count[ip] = int(hits)
        top = sorted(count, key=count.get, reverse=True)
        top5 = {}
        for ip in top[:5]:
            top5[ip] = int(redis.get(ip).decode("utf-8"))

    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    return top5



if __name__ == "__main__":
    application.run(host='0.0.0.0', port=81)

