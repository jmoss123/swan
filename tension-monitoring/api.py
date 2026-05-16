from flask import Flask, jsonify, request

app = Flask(__name__)

readings = []

@app.route('/readings', methods=['GET'])
def get_readings():
	return jsonify(readings)

@app.route('/readings', methods=['POST'])
def add_reading():
	data = request.get_json()
	readings.append(data)
	return jsonify(data), 201

if __name__ == '__main__':
	app.run(host='0.0.0.0', debug=True)
