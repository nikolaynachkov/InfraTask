FROM python:3.13.1-slim

ENV URLS=https://httpstat.us/503,https://httpstat.us/200
ENV PORT=8090
ENV TIMEOUT=2

WORKDIR /InfraTask

COPY http_check/ .

COPY RequiredModules/ .

RUN pip install -r modules.txt

CMD ["python", "run.py"]
