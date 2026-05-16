import os
from flask import Flask, jsonify, request

app = Flask(__name__)

readings = []

UPLOAD_FOLDER = "uploaded_cycles"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/readings', methods=['GET'])
def get_readings():
	return jsonify(readings)

# List all uploaded CSV files
@app.route('/csv_files', methods=['GET'])
def list_csv_files():
    files = os.listdir(UPLOAD_FOLDER)
    return jsonify(files)

# Download a specific CSV file by name
@app.route('/csv_files/<filename>', methods=['GET'])
def get_csv_file(filename):
    path = os.path.join(UPLOAD_FOLDER, filename)
    if not os.path.exists(path):
        return jsonify({"error": "File not found"}), 404
    return send_file(path, mimetype='text/csv', as_attachment=True)

@app.route('/readings', methods=['POST'])
def add_reading():
	data = request.get_json()
	readings.append(data)
	return jsonify(data), 201

@app.route('/upload_csv', methods=['POST'])
def upload_csv():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Empty filename"}), 400
    save_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(save_path)
    return jsonify({"message": f"Saved {file.filename}"}), 201

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "status": "running",
        "endpoints": [
            "GET  /readings",
            "POST /readings",
            "POST /upload_csv",
            "GET  /csv_files",
            "GET  /csv_files/<filename>"
        ]
    })

if __name__ == '__main__':
	app.run(host='0.0.0.0', debug=True)
