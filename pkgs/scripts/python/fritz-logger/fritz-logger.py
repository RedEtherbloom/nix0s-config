#!/usr/bin/env python3

import datetime
import time
import sqlite3
import os
from pathlib import Path

from fritzconnection.lib.fritzhosts import FritzHosts
from platformdirs import user_data_dir


def cls():
    os.system('cls' if os.name == 'nt' else 'clear')


appname = "fritz-logger"
# Irrelevant on linux
appauthor = "Etherbloom"


ip_address = os.environ.get("IP_ADDRESS", "fritz.box")
password_file = os.environ.get("PASSWORD_FILE")
if password_file is not None:
    password = Path(password_file).read_text().replace('\n', '')
else:
    password = os.environ.get("FRITZ_PASSWORD")

clear_screen: bool = os.environ.get("CLEAN_SCREEN", False)
# Run in background every query seconds
daemon_mode = True if os.environ.get("FRITZ_DAEMON_MODE") == "1" else False
if daemon_mode:
    # Every n seconds
    query_period: int = int(os.environ.get("QUERY_PERIOD", 15 * 60))
    # In days
    prune_older_than: int = int(os.environ.get("PRUNE_OLDER_THAN", 14))
    data_dir = os.environ.get("DATA_DIR")
    if data_dir is None:
        data_dir = str(user_data_dir(appname, appauthor, ensure_exists=True))
    else:
        data_dir = Path(data_dir)
        data_dir.mkdir(mode=0o777, parents=True, ensure_exists=True)
        data_dir = str(data_dir)

    data_dir = Path(data_dir)

    database_connection = sqlite3.connect(
        data_dir.joinpath('active_hosts_data.db'))
    cursor = database_connection.cursor()

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS active_devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        ip TEXT,
        mac TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    ''')
    database_connection.commit()

fc = FritzHosts(address=ip_address, password=password)

while True:
    if clear_screen:
        cls()
    print(f"Current time {datetime.datetime.now()}")
    # Get list of connected devices
    active_devices = fc.get_active_hosts()

    for device in active_devices:
        print((
            f"Name: {device['name']}, "
            f"IP: {device['ip']}, "
            f"MAC: {device['mac']}"
        ))
        if daemon_mode:
            cursor.execute(
                '''INSERT INTO active_devices (name, ip, mac) \
                    VALUES (?, ?, ?)''',
                (device['name'], device['ip'], device['mac'])
            )

    if daemon_mode:
        database_connection.commit()
        cursor.execute(f"DELETE FROM active_devices WHERE timestamp \
            < date('now', '-{prune_older_than} days')")
        database_connection.commit()
        if cursor.rowcount > 0:
            print(f"Deleted {cursor.rowcount} old entries from db")
        time.sleep(query_period)
    else:
        break

if daemon_mode:
    database_connection.close()
