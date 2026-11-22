from flask import Flask, render_template
import pyodbc
from sympy import true

app = Flask(__name__)

def baglan():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=Vehicle_management;"
        "Trusted_connection=yes;"
        "TrustServerCertificate=yes"
    )
@app.route('/araclar')
def araclar():
    conn = baglan()
    cursor = conn.cursor()
    cursor.execute("Select plate, model_year, fuel_type, daily_price, status from vehicles order by plate")
    satirlar = cursor.fetchall()
    conn.close()
    return render_template("araclar.html", araclar=satirlar)

if __name__ == '__main__':
    app.run(debug=True)