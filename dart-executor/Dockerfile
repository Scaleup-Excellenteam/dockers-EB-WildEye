FROM alpine:3.18

RUN apk add --no-cache bash curl python3 py3-pip
RUN curl -o /tmp/dart.zip https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip && \
    unzip /tmp/dart.zip -d /opt && \
    rm /tmp/dart.zip
ENV PATH="/opt/dart-sdk/bin:${PATH}"
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5003
CMD ["python3", "app.py"]