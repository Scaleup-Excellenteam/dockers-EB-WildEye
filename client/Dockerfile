FROM alpine:3.18

RUN apk add --no-cache bash curl python3 py3-pip
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY app.py .

EXPOSE 5005

CMD ["python3", "app.py"]