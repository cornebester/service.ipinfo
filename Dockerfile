# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:3.10.2-slim-bullseye
# python:slim-buster

# Add PS to troubleshoot pids adds ~20MB
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    net-tools iproute2 procps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# Install pip requirements
ADD ./src/requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

WORKDIR /src
ADD ./src/ /src

# Switching to a non-root user, please refer to https://aka.ms/vscode-docker-python-user-rights
RUN useradd appuser && chown -R appuser /src
USER appuser

## optional more for documentaion as -p override
EXPOSE 81/tcp 

# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
# CMD ["python", "/src/application.py"]
# CMD ["gunicorn", "-b", "0.0.0.0:81", "--access-logfile=-", "--error-logfile=-", "--log-level=${LOG_LEVEL}" "application"]
# CMD gunicorn -b 0.0.0.0:81 --access-logfile=- --error-logfile=- --log-level=${LOG_LEVEL} application
CMD gunicorn -b 0.0.0.0:${WSGI_PORT:-8081} --access-logfile=- --error-logfile=- --log-level=${LOG_LEVEL} --timeout=600 --workers=4 application