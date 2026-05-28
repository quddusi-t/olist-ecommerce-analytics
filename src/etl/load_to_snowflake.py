"""
Load Olist CSV files into Snowflake OLIST_ANALYTICS.OLIST_RAW schema.

Reads all 9 raw CSVs, uppercases column names, and writes to Snowflake
using write_pandas with auto table creation.

Usage:
    python src/etl/load_to_snowflake.py

Environment Variables (Required):
    SNOWFLAKE_PASSWORD

Optional (defaults match profiles.yml):
    SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_ROLE,
    SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE
"""

import logging
import os
import sys
from pathlib import Path

import pandas as pd
import snowflake.connector
from dotenv import load_dotenv
from snowflake.connector.pandas_tools import write_pandas

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

load_dotenv()

RAW_DIR = Path(__file__).parents[2] / "data" / "raw"
DATABASE = os.getenv("SNOWFLAKE_DATABASE", "OLIST_ANALYTICS")
SCHEMA = "OLIST_RAW"

# Maps CSV filename → Snowflake table name
TABLES = {
    "olist_orders_dataset.csv": "ORDERS",
    "olist_order_items_dataset.csv": "ORDER_ITEMS",
    "olist_order_payments_dataset.csv": "ORDER_PAYMENTS",
    "olist_order_reviews_dataset.csv": "ORDER_REVIEWS",
    "olist_customers_dataset.csv": "CUSTOMERS",
    "olist_sellers_dataset.csv": "SELLERS",
    "olist_products_dataset.csv": "PRODUCTS",
    "olist_geolocation_dataset.csv": "GEOLOCATION",
    "product_category_name_translation.csv": "PRODUCT_CATEGORY_NAME_TRANSLATION",
}


def sf_conn():
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT", "sa61806.europe-west3.gcp"),
        user=os.getenv("SNOWFLAKE_USER", "ktusuz"),
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.getenv("SNOWFLAKE_ROLE", "SYSADMIN"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
        database=DATABASE,
        schema=SCHEMA,
    )


def setup_database(conn) -> None:
    cur = conn.cursor()
    cur.execute(f"CREATE DATABASE IF NOT EXISTS {DATABASE}")
    cur.execute(f"CREATE SCHEMA IF NOT EXISTS {DATABASE}.{SCHEMA}")
    logger.info("Database %s and schema %s ready", DATABASE, SCHEMA)


def load_table(conn, csv_file: str, table_name: str) -> None:
    path = RAW_DIR / csv_file
    logger.info("Reading %s ...", csv_file)
    df = pd.read_csv(path, low_memory=False)
    df.columns = [c.upper() for c in df.columns]
    logger.info("  %d rows, %d columns", len(df), len(df.columns))

    cur = conn.cursor()
    cur.execute(f"DROP TABLE IF EXISTS {SCHEMA}.{table_name}")

    success, n_chunks, n_rows, _ = write_pandas(
        conn,
        df,
        table_name=table_name,
        schema=SCHEMA,
        database=DATABASE,
        auto_create_table=True,
        overwrite=True,
    )
    if not success:
        raise RuntimeError(f"write_pandas failed for {table_name}")
    logger.info("[OK] %s -> %s: %d rows", csv_file, table_name, n_rows)


def main() -> None:
    if not os.getenv("SNOWFLAKE_PASSWORD"):
        logger.error("SNOWFLAKE_PASSWORD not set")
        sys.exit(1)

    conn = sf_conn()
    try:
        setup_database(conn)
        for csv_file, table_name in TABLES.items():
            load_table(conn, csv_file, table_name)
    finally:
        conn.close()

    logger.info("[OK] All %d tables loaded into %s.%s", len(TABLES), DATABASE, SCHEMA)


if __name__ == "__main__":
    main()
