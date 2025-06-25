from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Improved HTML with better JavaScript
HTML = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Executor Test</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; margin: 2em; background-color: #f4f4f4; color: #333; }
        .container { max-width: 800px; margin: auto; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h1, h2 { color: #444; }
        select, textarea, button { width: 100%; padding: 10px; margin-bottom: 10px; border-radius: 4px; border: 1px solid #ddd; }
        button { background-color: #007BFF; color: white; border: none; cursor: pointer; font-size: 1em; }
        button:hover { background-color: #0056b3; }
        pre { background-color: #eee; padding: 15px; border-radius: 4px; white-space: pre-wrap; word-wrap: break-word; }
        #error { color: red; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Multi-Language Code Executor Test</h1>
        <form id="codeForm">
            <label for="lang">Select Language:</label>
            <select name="lang" id="langSelect">
                <option value="python">Python</option>
                <option value="java">Java</option>
                <option value="dart">Dart</option>
            </select>
            <br><br>
            <label for="code">Enter Code:</label>
            <textarea name="code" id="codeInput" rows="12" cols="50"></textarea>
            <br><br>
            <button type="submit" id="executeBtn">Execute</button>
        </form>
        <h2>Output:</h2>
        <pre id="output">Execution results will appear here.</pre>
        <pre id="error"></pre>
    </div>

    <script>
        // Store sample code for each language
        const sampleCode = {
            python: 'print("Hello from Python!")',
            java: 'public class Main {\\n    public static void main(String[] args) {\\n        System.out.println("Hello from Java!");\\n    }\\n}',
            dart: 'void main() {\\n  print("Hello from Dart!");\\n}'
        };

        const langSelect = document.getElementById('langSelect');
        const codeInput = document.getElementById('codeInput');
        const outputArea = document.getElementById('output');
        const errorArea = document.getElementById('error');
        const executeBtn = document.getElementById('executeBtn');

        // Function to update the code text area
        function updateCodeSample() {
            const selectedLang = langSelect.value;
            codeInput.value = sampleCode[selectedLang];
        }

        // Add event listener to the dropdown
        langSelect.addEventListener('change', updateCodeSample);

        // Set the initial code sample when the page loads
        document.addEventListener('DOMContentLoaded', updateCodeSample);

        // Handle the form submission
        document.getElementById('codeForm').onsubmit = async (e) => {
            e.preventDefault();
            outputArea.textContent = 'Executing...';
            errorArea.textContent = '';
            executeBtn.disabled = true;

            const formData = new FormData();
            const code = codeInput.value;
            const lang = langSelect.value;

            try {
                const blob = new Blob([code], {type: 'text/plain'});
                formData.append('file', blob, 'code.' + lang); // Use proper extension
                formData.append('lang', lang);

                // 1. Upload file to router
                const uploadResp = await fetch('http://localhost:5004/upload', {
                    method: 'POST',
                    body: formData
                });

                if (!uploadResp.ok) {
                    throw new Error('Upload failed. Status: ' + uploadResp.status);
                }

                const uploadResult = await uploadResp.json();
                if (uploadResult.error) {
                     throw new Error('Upload Error: ' + uploadResult.error);
                }
                const file_id = uploadResult.file_id;

                // 2. Execute code via router
                const execResp = await fetch(`http://localhost:5004/execute/${file_id}`);

                if (!execResp.ok) {
                     throw new Error('Execution request failed. Status: ' + execResp.status);
                }

                const result = await execResp.json();

                // Display result
                outputArea.textContent = result.stdout || '(No standard output)';
                if (result.stderr) {
                    errorArea.textContent = 'Error Output:\\n' + result.stderr;
                }

            } catch (err) {
                outputArea.textContent = 'An error occurred.';
                errorArea.textContent = err.message;
            } finally {
                executeBtn.disabled = false;
            }
        };
    </script>
</body>
</html>
'''.strip()

@app.route('/')
def index():
    return render_template_string(HTML)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5005)