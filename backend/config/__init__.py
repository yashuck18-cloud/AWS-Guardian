"""Django configuration package."""
import pymysql

pymysql.install_as_MySQLdb()

# Compatibility patch for XAMPP MariaDB 10.4 with Django 5.x
try:
    from django.db.backends.mysql.base import DatabaseWrapper
    from django.db.backends.mysql.features import DatabaseFeatures

    DatabaseWrapper.check_database_version_supported = lambda self: None
    DatabaseFeatures.can_return_columns_from_insert = False
except Exception:
    pass
