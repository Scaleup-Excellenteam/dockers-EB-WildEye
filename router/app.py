from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/execute', methods=['POST'])
def execute():
    payload = request.json or {}
    lang = payload.get("lang")
    code = payload.get("code", "")

    if lang == "python":
        url = "http://python-executor:5001/execute"
    elif lang == "java":
        url = "http://java-executor:5002/execute"
    elif lang == "dart":
        url = "http://dart-executor:5003/execute"
    else:
        return jsonify({"error": "unsupported language"}), 400

    # forward the code to the appropriate executor
    resp = requests.post(url, json={"code": code})
    return jsonify(resp.json()), resp.status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
