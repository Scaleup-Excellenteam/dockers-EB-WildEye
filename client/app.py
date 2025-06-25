from flask import Flask, render_template_string
import requests

app = Flask(__name__)

# Simple HTML template
HTML = '''
<!DOCTYPE html>
<html>
<head>
    <title>Code Executor Test</title>
</head>
<body>
    <h1>Multi-Language Code Executor Test</h1>
    <form id="codeForm">
        <select name="lang">
            <option value="python">Python</option>
            <option value="java">Java</option>
            <option value="dart">Dart</option>
        </select>
        <br><br>
        <textarea name="code" rows="10" cols="50">print("Hello World")</textarea>
        <br><br>
        <button type="submit">Execute</button>
    </form>
    <h2>Output:</h2>
    <pre id="output"></pre>
    
    <script>
    document.getElementById('codeForm').onsubmit = async (e) => {
        e.preventDefault();
        const formData = new FormData();
        const code = e.target.code.value;
        const lang = e.target.lang.value;
        
        // Create file from code
        const blob = new Blob([code], {type: 'text/plain'});
        formData.append('file', blob, 'code.txt');
        formData.append('lang', lang);
        
        // Upload file
        const uploadResp = await fetch('http://localhost:5004/upload', {
            method: 'POST',
            body: formData
        });
        const {file_id} = await uploadResp.json();
        
        // Execute code
        const execResp = await fetch(`http://localhost:5004/execute/${file_id}`);
        const result = await execResp.json();
        
        document.getElementById('output').textContent = result.stdout || result.stderr || 'No output';
    };
    </script>
</body>
</html>
'''

@app.route('/')
def index():
    return render_template_string(HTML)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5005)