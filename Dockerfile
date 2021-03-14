FROM python:3-alpine
RUN pip install --no-cache Flask waitress
COPY app.py app.py

ENTRYPOINT ["python", "app.py"]
