from flask import Flask, render_template_string, request
import requests

app = Flask(__name__)

TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Magic Container Service</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: #f8f9fa; }
        .container { max-width: 600px; margin-top: 60px; }
        .card { box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-body">
                <h2 class="card-title mb-4 text-center">Magic Container Service</h2>
                <form method="post">
                    <div class="mb-3">
                        <label for="rhs" class="form-label">Enter RHS value</label>
                        <input type="number" class="form-control" id="rhs" name="rhs" value="{{ rhs|default(3) }}" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Call Service</button>
                </form>
                {% if result %}
                <hr>
                <h5 class="mt-4">Raw Result:</h5>
                <pre class="bg-light p-3">{{ result }}</pre>
                {% endif %}
                {% if mwdata and mwsize %}
                <hr>
                <h5 class="mt-4">Matrix Output:</h5>
                <div id="matrix-table"></div>
                <script src="https://cdn.sheetjs.com/xlsx-latest/package/dist/xlsx.full.min.js"></script>
                <script>
                // Reshape mwdata into 2D array
                const mwdata = {{ mwdata|tojson }};
                const mwsize = {{ mwsize|tojson }};
                if (mwdata && mwsize && mwsize.length === 2) {
                    const rows = mwsize[0];
                    const cols = mwsize[1];
                    let matrix = [];
                    for (let r = 0; r < rows; r++) {
                        let row = [];
                        for (let c = 0; c < cols; c++) {
                            row.push(mwdata[r * cols + c]);
                        }
                        matrix.push(row);
                    }
                    // Create HTML table
                    let html = '<table class="table table-bordered table-striped">';
                    for (let r = 0; r < matrix.length; r++) {
                        html += '<tr>';
                        for (let c = 0; c < matrix[r].length; c++) {
                            html += `<td>${matrix[r][c]}</td>`;
                        }
                        html += '</tr>';
                    }
                    html += '</table>';
                    document.getElementById('matrix-table').innerHTML = html;
                }
                </script>
                {% endif %}
                {% if error %}
                <div class="alert alert-danger mt-3">{{ error }}</div>
                {% endif %}
            </div>
        </div>
    </div>
</body>
</html>
'''

@app.route('/', methods=['GET', 'POST'])
def index():
    result = None
    error = None
    rhs = 3
    mwdata = None
    mwsize = None
    if request.method == 'POST':
        try:
            rhs = int(request.form['rhs'])
            payload = {"nargout": 1, "rhs": [rhs]}
            headers = {"Content-Type": "application/json"}
            url = "https://improved-umbrella-s5cy.onrender.com/magiccontainer/mymagic"
            response = requests.post(url, json=payload, headers=headers, timeout=10)
            response.raise_for_status()
            result = response.json()
            # Extract mwdata and mwsize if present
            lhs = result.get('lhs', [{}])[0]
            mwdata = lhs.get('mwdata')
            mwsize = lhs.get('mwsize')
        except Exception as e:
            error = f"Error: {e}"
    return render_template_string(TEMPLATE, result=result, error=error, rhs=rhs, mwdata=mwdata, mwsize=mwsize)

if __name__ == '__main__':
    app.run(debug=True)
