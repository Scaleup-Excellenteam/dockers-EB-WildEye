FROM alpine:3.18

RUN apk add --no-cache openjdk11 python3 py3-pip
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5002
CMD ["python3", "app.py"]