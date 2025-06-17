from flask import Flask, request, jsonify
import subprocess
import tempfile
import os

app = Flask(__name__)

@app.route('/execute', methods=['POST'])
def execute():
    data = request.get_json()
    code = data.get('code', '')

    with tempfile.NamedTemporaryFile(mode='w', suffix='.java', delete=False) as tmp_file:
        tmp_file.write(code)
        tmp_file_path = tmp_file.name
        class_name = os.path.splitext(os.path.basename(tmp_file_path))[0]

    try:
        # Compile the Java code
        compile_result = subprocess.run(
            ['javac', tmp_file_path],
            capture_output=True,
            text=True,
            timeout=10
        )

        if compile_result.returncode != 0:
            output = {
                'stdout': '',
                'stderr': compile_result.stderr
            }
        else:
            # Run the compiled Java code
            run_result = subprocess.run(
                ['java', '-cp', os.path.dirname(tmp_file_path), class_name],
                capture_output=True,
                text=True,
                timeout=10
            )
            output = {
                'stdout': run_result.stdout,
                'stderr': run_result.stderr
            }

    except subprocess.TimeoutExpired:
        output = {
            'stdout': '',
            'stderr': 'Execution timed out'
        }
    finally:
        if os.path.exists(tmp_file_path):
            os.remove(tmp_file_path)
        class_file_path = os.path.join(os.path.dirname(tmp_file_path), class_name + '.class')
        if os.path.exists(class_file_path):
            os.remove(class_file_path)

    return jsonify(output)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)