FROM openjdk:11-jdk-slim

# Install Python and pip
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the Flask application
COPY app.py .

# Expose the port and run the application
EXPOSE 5002
CMD ["python3", "app.py"]