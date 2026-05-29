"""
Olist daily dbt pipeline.

Schedule: daily at 06:00 UTC
Tasks:
    dbt_seed       → load/refresh seed tables
    dbt_run        → build all staging views + mart tables
    dbt_test       → data quality gate (fails DAG if any test fails)
    notify_success → Slack alert on clean run

Slack alerting:
    - on_failure_callback fires on any task failure
    - Requires an Airflow Connection named 'slack_webhook' with the
      Slack incoming webhook URL as the Host field
    - If the connection is absent the callback logs a warning and continues
      (safe for local dev without Slack configured)

SNOWFLAKE_PASSWORD is injected into the container via docker-compose.yml
and inherited by BashOperator tasks automatically.
"""

import logging
import urllib.request
import json
from datetime import datetime, timedelta

from airflow import DAG
from airflow.hooks.base import BaseHook
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

log = logging.getLogger(__name__)

DBT_BIN = "/home/airflow/.local/bin/dbt"
DBT_DIR = "/opt/airflow/dbt_project"
DBT_FLAGS = "--log-path /tmp/dbt-logs"
SLACK_CONN_ID = "slack_webhook"


def _send_slack(message: str) -> None:
    """Post to Slack via the slack_webhook Airflow connection.
    Silently skips if the connection is not configured."""
    try:
        conn = BaseHook.get_connection(SLACK_CONN_ID)
        webhook_url = conn.host
    except Exception:
        log.warning("Slack connection '%s' not found — skipping alert", SLACK_CONN_ID)
        return

    payload = json.dumps({"text": message}).encode()
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req, timeout=10)


def _on_failure(context) -> None:
    dag_id = context["dag"].dag_id
    task_id = context["task_instance"].task_id
    run_id = context["run_id"]
    log_url = context["task_instance"].log_url
    _send_slack(
        f":red_circle: *{dag_id}* failed\n"
        f"Task: `{task_id}`  |  Run: `{run_id}`\n"
        f"<{log_url}|View logs>"
    )


def _notify_success(**context) -> None:
    dag_id = context["dag"].dag_id
    run_id = context["run_id"]
    _send_slack(
        f":large_green_circle: *{dag_id}* completed successfully\n" f"Run: `{run_id}`"
    )


default_args = {
    "owner": "olist_analytics",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": _on_failure,
}

with DAG(
    dag_id="olist_daily_pipeline",
    description="Daily dbt run + data quality gate for Olist analytics",
    schedule="0 6 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=default_args,
    tags=["olist", "dbt", "snowflake"],
) as dag:

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"cd {DBT_DIR} && {DBT_BIN} {DBT_FLAGS} seed",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {DBT_DIR} && {DBT_BIN} {DBT_FLAGS} run",
    )

    # Data quality gate — DAG stops here if any test fails
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_DIR} && {DBT_BIN} {DBT_FLAGS} test",
    )

    notify_success = PythonOperator(
        task_id="notify_success",
        python_callable=_notify_success,
        on_failure_callback=None,  # don't double-alert if notify itself fails
    )

    dbt_seed >> dbt_run >> dbt_test >> notify_success
