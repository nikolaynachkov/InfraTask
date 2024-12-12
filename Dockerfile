FROM python:3.13

WORKDIR /InfraTask

COPY http_check/ .

COPY RequiredModules/ .

RUN pip install -r modules.txt

CMD ["python", "run.py"]
