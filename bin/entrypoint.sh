#!/bin/sh -e

# Fix reboot loop issue (`A server is already running. Check
# /app/test/tmp/pids/server.pid.`).
rm -rf /app/test/tmp/pids/server.pid

exec "$@"
