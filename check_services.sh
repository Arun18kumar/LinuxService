#!/bin/bash

# Remote server details
REMOTE_SERVER="10.9.22.151"
REMOTE_USERNAME="arun"
REMOTE_PASSWORD="andaman@123"
REMOTE_SERVICES=("postgresql" "serverbeagle" "servercentral")
LOCAL_PASSWORD="tenet"
LOCAL_SERVICES=("serverbeagle" "servercentral")
PING_COUNT=4

# Ping the remote server
echo "Pinging $REMOTE_SERVER with $PING_COUNT attempts..."
if ping -c $PING_COUNT $REMOTE_SERVER > /dev/null 2>&1; then
    echo "Ping to $REMOTE_SERVER successful!"

    # Check the status of Beagle service on the remote server
    BEAGLESTATUS=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USERNAME}@${REMOTE_SERVER}" \
        echo '${REMOTE_PASSWORD}' | sudo -S systemctl is-active '${REMOTE_SERVICES[1]}')
    echo "${REMOTE_SERVICES[1]} on remote server is $BEAGLESTATUS"

    if [ "$BEAGLESTATUS" != "active" ]; then
        echo "Beagle service on remote is inactive. Stopping services on remote server..."
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USERNAME}@${REMOTE_SERVER}" \
            "echo '${REMOTE_PASSWORD}' | sudo -S systemctl stop '${REMOTE_SERVICES[1]}' && \
             echo '${REMOTE_PASSWORD}' | sudo -S systemctl stop '${REMOTE_SERVICES[2]}'"
        
        echo "Starting corresponding services on local server..."
        echo "${LOCAL_PASSWORD}" | sudo -S systemctl start "${LOCAL_SERVICES[0]}"
        LOCAL_BEAGLE_STATUS=$(systemctl is-active "${LOCAL_SERVICES[0]}")
        echo "Local ${LOCAL_SERVICES[0]} status: $LOCAL_BEAGLE_STATUS"

        echo "${LOCAL_PASSWORD}" | sudo -S systemctl start "${LOCAL_SERVICES[1]}"
        LOCAL_CENTRAL_STATUS=$(systemctl is-active "${LOCAL_SERVICES[1]}")
        echo "Local ${LOCAL_SERVICES[1]} status: $LOCAL_CENTRAL_STATUS"
    else
        echo "Beagle service on remote is active. No action needed locally."
    fi

    # Check the status of Central service on the remote server
    CENTRALSTATUS=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USERNAME}@${REMOTE_SERVER}" \
        echo '${REMOTE_PASSWORD}' | sudo -S systemctl is-active '${REMOTE_SERVICES[2]}')
    echo "${REMOTE_SERVICES[2]} on remote server is $CENTRALSTATUS"

    if [ "$CENTRALSTATUS" != "active" ]; then
        echo "Central service on remote is inactive. Stopping services on remote server..."
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USERNAME}@${REMOTE_SERVER}" \
            "echo '${REMOTE_PASSWORD}' | sudo -S systemctl stop '${REMOTE_SERVICES[1]}' && \
             echo '${REMOTE_PASSWORD}' | sudo -S systemctl stop '${REMOTE_SERVICES[2]}'"
        
        echo "Starting corresponding services on local server..."
        echo "${LOCAL_PASSWORD}" | sudo -S systemctl start "${LOCAL_SERVICES[0]}"
        LOCAL_BEAGLE_STATUS=$(systemctl is-active "${LOCAL_SERVICES[0]}")
        echo "Local ${LOCAL_SERVICES[0]} status: $LOCAL_BEAGLE_STATUS"

        echo "${LOCAL_PASSWORD}" | sudo -S systemctl start "${LOCAL_SERVICES[1]}"
        LOCAL_CENTRAL_STATUS=$(systemctl is-active "${LOCAL_SERVICES[1]}")
        echo "Local ${LOCAL_SERVICES[1]} status: $LOCAL_CENTRAL_STATUS"
    else
        echo "Central service on remote is active. No action needed locally."
    fi
    echo "$BEAGLESTATUS and $CENTRALSTATUS"
    if [ "$CENTRALSTATUS" == "active" ] && [ "$BEAGLESTATUS" == "active" ]; then
        STATUS=$(echo '${LOCAL_PASSWORD}' | sudo -S systemctl is-active '${LOCAL_SERVICES[0]}')
        if [ "$STATUS" == "active" ]; then
            echo '${LOCAL_PASSWORD}' | sudo -S systemctl stop '${LOCAL_SERVICES[0]}'
            echo "${LOCAL_SERVICES[0]} is running on both server so stopping locally"
        fi             
        STATUS=$(echo '${LOCAL_PASSWORD}' | sudo -S systemctl is-active '${LOCAL_SERVICES[1]}')
        if [ "$STATUS" == "active" ]; then
            echo '${LOCAL_PASSWORD}' | sudo -S systemctl stop '${LOCAL_SERVICES[1]}' 
            echo "${LOCAL_SERVICES[1]} is running on both server so stopping locally"
        fi
    fi
else
    echo "Ping to $REMOTE_SERVER failed. Starting local services..."
    echo "${LOCAL_PASSWORD}" | sudo -S systemctl start "${LOCAL_SERVICES[0]}"
    echo "${LOCAL_SERVICES[0]} started locally."

    echo "${LOCAL_PASSWORD}" | sudo -S systemctl start "${LOCAL_SERVICES[1]}"
    echo "${LOCAL_SERVICES[1]} started locally."
fi

DATABASEBACKUP=$(echo '${LOCAL_PASSWORD}' | sudo -S systemctl is-active databasebackup.service )
echo "${DATABASEBACKUP}"
if [ "$DATABASEBACKUP" == "inactive" ]; then
    echo "Database backup is inactive. activating ..."
    echo '${LOCALPASSWORD}' | sudo -S systemctl start databasebackup
fi
