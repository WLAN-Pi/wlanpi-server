#!/bin/bash

# Server mode is non-persistent by design. This service schedule switch to Classic mode at the next boot.
# To use WLAN Pi in Server mode permanently, execute: sudo systemctl disable wlanpi-server-nonpersistence.service

SCRIPT_NAME="$(basename "$0")"

# Shows help
show_help(){
    echo "Server mode non-persistence service"
    echo
    echo "Usage:"
    echo "  $SCRIPT_NAME"
    echo
    echo "Options:"
    echo "  -d, --debug    Enable debugging output"
    echo "  -h, --help     Show this screen"
    echo
    exit 0
}

# Pass debug argument to the script to enable debugging output
DEBUG=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--debug) DEBUG=1 ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Displays debug output
debugger() {
    if [ "$DEBUG" -ne 0 ];then
      echo "Debugger: $1"
    fi
}

########## Server mode non-persistence ##########

if grep -q "server" /etc/wlanpi-state; then
    debugger "WLAN Pi is in Server mode"

    if [ -f "/etc/wlanpi-stay-in-server-mode" ]; then
        debugger "File /etc/wlanpi-stay-in-server-mode exists, staying in Server mode"
        rm /etc/wlanpi-stay-in-server-mode

        # Check if the file was removed successfully.
        if [ $? -eq 0 ]; then
            debugger "File /etc/wlanpi-stay-in-server-mode removed successfully"
        else
            echo "Error: Failed to remove file /etc/wlanpi-stay-in-server-mode"
            exit 1
        fi
    else
        debugger "File /etc/wlanpi-stay-in-server-mode does not exist, switching to Classic mode"
        /usr/sbin/server_switcher off
    fi
else
    debugger "WLAN Pi isn't in Server mode, taking no action"
fi
