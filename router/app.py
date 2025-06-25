from flask import Flask, request, jsonify
import requests
import os
import tempfile
import uuid

app = Flask(__name__)

# Store file mappings
file_storage = {}

@app.route('/upload', methods=['POST'])
def upload():
    """Handle POST requests with code files"""
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    file = request.files['file']
    lang = request.form.get('lang')
    
    if not lang or lang not in ['python', 'java', 'dart']:
        return jsonify({"error": "Invalid or missing language"}), 400
    
    # Generate unique ID for this upload
    file_id = str(uuid.uuid4())
    
    # Save file to temp directory
    temp_dir = tempfile.gettempdir()
    file_path = os.path.join(temp_dir, f"{file_id}_{file.filename}")
    file.save(file_path)
    
    # Store mapping
    file_storage[file_id] = {
        'path': file_path,
        'lang': lang,
        'filename': file.filename
    }
    
    return jsonify({"file_id": file_id}), 200

@app.route('/execute/<file_id>', methods=['GET'])
def execute(file_id):
    """Handle GET requests to execute code"""
    if file_id not in file_storage:
        return jsonify({"error": "File not found"}), 404
    
    file_info = file_storage[file_id]
    
    # Read code from file
    with open(file_info['path'], 'r') as f:
        code = f.read()
    
    # Forward to appropriate executor
    lang = file_info['lang']
    if lang == "python":
        url = "http://python-executor:5001/execute"
    elif lang == "java":
        url = "http://java-executor:5002/execute"
    elif lang == "dart":
        url = "http://dart-executor:5003/execute"
    
    # Send code to executor
    resp = requests.post(url, json={"code": code})
    
    # Clean up file
    os.remove(file_info['path'])
    del file_storage[file_id]
    
    return jsonify(resp.json()), resp.status_code

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)