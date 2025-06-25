FROM alpine:3.18
RUN apk add --no-cache python3 py3-pip
WORKDIR /app
RUN pip3 install flask
COPY app.py .
EXPOSE 5005
CMD ["python3", "app.py"]