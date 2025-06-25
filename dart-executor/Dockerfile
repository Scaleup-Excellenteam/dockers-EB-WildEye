# STEP 1: Start from the official Dart image. It's guaranteed to work.
FROM dart:stable-sdk

# STEP 2: The Dart image is based on Debian Linux.
RUN apt-get update && apt-get install -y python3 python3-pip

# STEP 3: Set up the Python application inside the Dart container.
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt --break-system-packages
COPY app.py .

EXPOSE 5003

# STEP 4: Run the Flask app.
CMD ["python3", "app.py"]