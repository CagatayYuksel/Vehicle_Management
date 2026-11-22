import pyodbc

conn = pyodbc.connect (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=Vehicle_management;"
    "Trusted_connection=yes;"
    "TrustServerCertificate=yes"
)

cursor = conn.cursor()
cursor.execute("SELECT COUNT(*) FROM Vehicles")
sayi = cursor.fetchone()[0]
print("Toplam araç sayısı:", sayi)

cursor.execute("SELECT plate, daily_price, status from Vehicles")
satirlar = cursor.fetchall()

for satir in satirlar[:5]:
    print(satir.plate, satir.daily_price, satir.status)

conn.close()