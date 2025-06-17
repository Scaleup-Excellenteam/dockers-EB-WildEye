FROM openjdk:11-jre-slim

# Install Python and Flask
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install Flask

# Copy the Flask application
COPY app.py /app/
WORKDIR /app

# Expose the port and run the application
EXPOSE 5002
CMD ["python3", "app.py"]