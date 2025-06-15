from flask import Flask, request, jsonify
app = Flask(__name__)

@app.route('/execute', methods=['POST'])
def execute():
    data = request.json or {} 
    return jsonify({"recived: " data}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)