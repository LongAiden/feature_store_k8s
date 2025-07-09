import requests
import json
import os
import sys
import time
import datetime as dt

KAFKA_RETRIES = 30
KAFKA_SLEEP = 5
KAFKA_CONNECT_URL = os.getenv('KAFKA_CONNECT_URL', 'http://localhost:8083')
CONNECTOR_NAME = os.getenv('CONNECTOR_NAME', 'postgres-cdc')

def get_connector_status():
    """Gets the status of the specific connector."""
    url = f'{KAFKA_CONNECT_URL}/connectors/{CONNECTOR_NAME}/status'
    try:
        response = requests.get(url)
        # It's normal to get a 404 if the connector hasn't been created by the Helm chart yet
        if response.status_code == 404:
            print(f"Connector '{CONNECTOR_NAME}' not found yet. Waiting for it to be created...")
            return None
        response.raise_for_status() 
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error getting connector status: {e}")
        return None

def wait_for_connector_running():
    """Waits for the connector and its tasks to be in a RUNNING state."""
    print(f"Waiting for connector '{CONNECTOR_NAME}' to be in RUNNING state...")
    
    for i in range(KAFKA_RETRIES):
        status = get_connector_status()
        
        if status and status.get('connector', {}).get('state') == 'RUNNING':
            tasks = status.get('tasks', [])
            if not tasks:
                print("Connector is RUNNING, but has no tasks yet. Waiting...")
            # Check if at least one task is also running
            elif any(task.get('state') == 'RUNNING' for task in tasks):
                print(f"Success! Connector '{CONNECTOR_NAME}' and at least one task are RUNNING.")
                print(json.dumps(status, indent=2))
                return # Exit successfully
            else:
                task_states = [t.get('state') for t in tasks]
                print(f"Connector state is RUNNING, but waiting for tasks. Current task states: {task_states}")
        
        else:
            current_state = status.get('connector', {}).get('state') if status else 'NOT FOUND'
            if current_state == 'FAILED':
                print(f"Error: Connector '{CONNECTOR_NAME}' has FAILED. Please check the Kafka Connect logs.")
                print(json.dumps(status, indent=2))
                sys.exit(1) # Exit with error
            print(f"Current state is '{current_state}'. Retrying in {KAFKA_SLEEP} seconds...")

        time.sleep(KAFKA_SLEEP)
    
    # This block runs if the loop completes without returning (i.e., a timeout)
    print(f"\nTimeout: Connector '{CONNECTOR_NAME}' did not become healthy after {KAFKA_RETRIES * KAFKA_SLEEP} seconds.")
    final_status = get_connector_status()
    if final_status:
        print("Last known status:")
        print(json.dumps(final_status, indent=2))
    sys.exit(1)

if __name__ == "__main__":
    print(f"Waiting for Debezium connector '{CONNECTOR_NAME}' to be ready on Kafka Connect at {KAFKA_CONNECT_URL}...")
    wait_for_connector_running()