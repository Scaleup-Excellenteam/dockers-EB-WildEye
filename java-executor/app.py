from flask import Flask, request, jsonify
import subprocess
import tempfile
import os
import re

app = Flask(__name__)

@app.route('/execute', methods=['POST'])
def execute():
    data = request.get_json()
    
    # Validate input
    if not data or 'code' not in data:
        return jsonify({
            'stdout': '',
            'stderr': 'Error: No code provided'
        }), 400
    
    code = data.get('code', '').strip()
    if not code:
        return jsonify({
            'stdout': '',
            'stderr': 'Error: Empty code provided'
        }), 400

    # Create temporary directory for this execution
    temp_dir = tempfile.mkdtemp()
    java_file_path = os.path.join(temp_dir, 'Main.java')
    class_file_path = os.path.join(temp_dir, 'Main.class')
    
    try:
        # Fix class name 
        if 'class ' in code:
            # Replace existing class name with Main
            code = re.sub(r'class\s+\w+', 'class Main', code)
        else:
            # If no class declaration, wrap in Main class
            code = f"""public class Main {{
    public static void main(String[] args) {{
        {code}
    }}
}}"""

        # Write the Java code to Main.java
        with open(java_file_path, 'w') as f:
            f.write(code)

        # Compile the Java code
        compile_result = subprocess.run(
            ['javac', java_file_path],
            capture_output=True,
            text=True,
            timeout=10,
            cwd=temp_dir
        )

        if compile_result.returncode != 0:
            return jsonify({
                'stdout': '',
                'stderr': f'Compilation Error:\n{compile_result.stderr}'
            })

        # Run the compiled Java code
        run_result = subprocess.run(
            ['java', '-cp', temp_dir, 'Main'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        return jsonify({
            'stdout': run_result.stdout,
            'stderr': run_result.stderr
        })

    except subprocess.TimeoutExpired:
        return jsonify({
            'stdout': '',
            'stderr': 'Execution timed out (10 seconds limit)'
        })
    except Exception as e:
        return jsonify({
            'stdout': '',
            'stderr': f'Internal error: {str(e)}'
        })
    finally:
        # Cleanup temporary files
        try:
            if os.path.exists(java_file_path):
                os.remove(java_file_path)
            if os.path.exists(class_file_path):
                os.remove(class_file_path)
            os.rmdir(temp_dir)
        except:
            pass  # Ignore cleanup errors

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)