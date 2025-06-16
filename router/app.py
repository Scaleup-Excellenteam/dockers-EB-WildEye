from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/execute', methods=['POST'])
def execute():
    payload = request.json or {}
    if payload.get("lang") == "python":
        # forward to python-executor
        resp = requests.post(
            "http://python-executor:5001/execute",
            json={"code": payload.get("code", "")}
        )
        return jsonify(resp.json()), resp.status_code

    return jsonify({"error": "unsupported language"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
