from flask import Flask, jsonify, abort

app = Flask(__name__)

@app.route('/divide/<int:num1>/<int:num2>')
def divide_numbers(num1, num2):
    try:
        result = num1 / num2
        return jsonify({"result": result})
    except ZeroDivisionError:
        # Handle division by zero specifically
        return jsonify({"error": "Cannot divide by zero"}), 400
    except Exception as e:
        # Handle any other unexpected errors
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

@app.route('/process_data')
def process_data():
    try:
        # Simulate an operation that might fail
        data = some_external_api_call() # This function is not defined, for demonstration
        return jsonify({"message": "Data processed successfully", "data": data})
    except SomeSpecificAPIError as e:
        # Handle a specific API error
        return jsonify({"error": f"API error: {str(e)}"}), 400
    except Exception as e:
        # Catch any other general exceptions
        return jsonify({"error": "Failed to process data due to an internal error"}), 500

def some_external_api_call():
    # Placeholder for a function that might raise an error
    raise SomeSpecificAPIError("Failed to connect to external service")

class SomeSpecificAPIError(Exception):
    pass

if __name__ == '__main__':
    app.run(debug=True)