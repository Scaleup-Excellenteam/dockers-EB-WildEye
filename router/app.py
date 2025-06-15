from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/execute', methods=['POST'])
def execute():
    return jsonify({"message": "Hello from router"}), 200

if __name__ == '__main__':
    # bind to 0.0.0.0 so it’s reachable from outside the container
    app.run(host='0.0.0.0', port=5000)