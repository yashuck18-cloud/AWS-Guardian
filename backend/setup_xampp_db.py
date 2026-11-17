import pymysql
import sys

def recreate_mysql_db():
    host = '127.0.0.1'
    port = 3306
    user = 'root'
    password = ''
    db_name = 'aws_guardian'

    try:
        conn = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            charset='utf8mb4'
        )
        with conn.cursor() as cursor:
            cursor.execute(f"DROP DATABASE IF EXISTS `{db_name}`;")
            cursor.execute(f"CREATE DATABASE `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
            print(f"Clean database '{db_name}' initialized successfully in XAMPP MySQL.")
        conn.close()
        return True
    except Exception as e:
        print(f"Could not connect to XAMPP MySQL: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    recreate_mysql_db()
