import os
import sys
import sqlite3
import pymysql

def transfer_sqlite_to_mysql():
    sqlite_path = 'db.sqlite3'
    if not os.path.exists(sqlite_path):
        print("No db.sqlite3 found to transfer.")
        return

    sqlite_conn = sqlite3.connect(sqlite_path)
    sqlite_cursor = sqlite_conn.cursor()

    mysql_conn = pymysql.connect(
        host='127.0.0.1',
        port=3306,
        user='root',
        password='',
        database='aws_guardian',
        charset='utf8mb4'
    )
    mysql_cursor = mysql_conn.cursor()

    tables = [
        'guardian_users',
        'guardian_aws_accounts',
        'guardian_resources',
        'guardian_scans',
        'guardian_alerts',
        'guardian_notification_settings',
        'guardian_notification_history',
        'guardian_audit_logs',
    ]

    for table in tables:
        try:
            sqlite_cursor.execute(f"SELECT * FROM {table}")
            rows = sqlite_cursor.fetchall()
            if not rows:
                continue

            columns = [desc[0] for desc in sqlite_cursor.description]
            cols_str = ', '.join([f"`{c}`" for c in columns])
            placeholders = ', '.join(['%s'] * len(columns))

            query = f"INSERT IGNORE INTO `{table}` ({cols_str}) VALUES ({placeholders})"
            for row in rows:
                mysql_cursor.execute(query, row)
            mysql_conn.commit()
            print(f"Transferred {len(rows)} records from {table}")
        except Exception as e:
            print(f"Table {table}: {e}")

    sqlite_conn.close()
    mysql_conn.close()
    print("Database data sync complete.")

if __name__ == '__main__':
    transfer_sqlite_to_mysql()
