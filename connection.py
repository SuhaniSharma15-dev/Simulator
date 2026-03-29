import mysql.connector
from mysql.connector import pooling
from dotenv import load_dotenv
import os

load_dotenv()

_pool = pooling.MySQLConnectionPool(
    pool_name="simulator_pool",
    pool_size=5,
    host=os.getenv("DB_HOST", "localhost"),
    port=int(os.getenv("DB_PORT", 3306)),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME"),
)

def get_conn():
    return _pool.get_connection()

def query(sql, params=None):
    """Run a SELECT — returns list of dicts."""
    conn = get_conn()
    cur  = conn.cursor(dictionary=True)
    cur.execute(sql, params or ())
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows

def execute(sql, params=None):
    """Run INSERT / UPDATE / DELETE — auto commits."""
    conn = get_conn()
    cur  = conn.cursor()
    cur.execute(sql, params or ())
    conn.commit()
    cur.close()
    conn.close()

def execute_many(sql, param_list):
    """Bulk INSERT — auto commits."""
    conn = get_conn()
    cur  = conn.cursor()
    cur.executemany(sql, param_list)
    conn.commit()
    cur.close()
    conn.close()

def transaction(operations):
    """
    Run multiple writes atomically.
    Pass a list of (sql, params) tuples.
    Rolls back everything if any step fails.
    """
    conn = get_conn()
    cur  = conn.cursor()
    try:
        conn.start_transaction()
        for sql, params in operations:
            cur.execute(sql, params or ())
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cur.close()
        conn.close()
