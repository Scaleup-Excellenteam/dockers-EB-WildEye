FROM dart:stable

# Install Python and Flask using the system package manager
RUN apt-get update && \
    apt-get install -y python3 python3-flask

# Copy the Flask application
COPY app.py /app/
WORKDIR /app

# Expose the port and run the application
EXPOSE 5003
CMD ["python3", "app.py"]