#!/usr/bin/env bash
#####################################################
#
# Quickstart script to configure basic wireless
# parameters for server mode
#
# Note: the script assumes we are using wlan0
#
#####################################################
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root (e.g. use 'sudo')" 
   exit 1
fi

set -e

SSID=""
PSK=""
CHANNEL=
CONFIG_FILE=/etc/wlanpi-server/conf/hostapd.conf
DHCP_FILE=/etc/wlanpi-server/dhcp/dhcpd.conf
ISC_DHCP_FILE=/etc/wlanpi-server/default/isc-dhcp-server
INTERFACES_FILE=/etc/wlanpi-server/network/interfaces

STATUS_FILE="/etc/wlanpi-state"

# default values
INTERFACE_DEFAULT=wlan0
SSID_DEFAULT=wlanpi_server
KEY_DEFAULT=wifipros
COUNTRYCODE_DEFAULT=US
CHANNEL_DEFAULT=6

# global vars
INTERFACE=
SSID=
KEY=
COUNTRYCODE=
CHANNEL=

get_interface () {
    read -p "Please enter the network interface name to be used for the wireless connection [$INTERFACE_DEFAULT] : " INTERFACE
    if [ "$INTERFACE" == "" ]; then 
        SSID=$INTERFACE_DEFAULT;
    fi
    return
}

get_ssid () {
    read -p "Please enter the network name of the wireless connection [$SSID_DEFAULT] : " SSID
    if [ "$SSID" == "" ]; then 
        SSID=$SSID_DEFAULT;
    fi
    return
}

get_psk () {
    # prompt for psk 
    read -p "Enter the network key [$KEY_DEFAULT]: " KEY
    if [ "$KEY" == "" ]; then 
        KEY=$KEY_DEFAULT;
    fi
    return
}

get_country () {
    # prompt for psk 
    read -p "Enter the two letter code for your country [$COUNTRYCODE_DEFAULT]: " COUNTRYCODE
    if [ "$COUNTRYCODE" == "" ]; then 
        COUNTRYCODE=$COUNTRYCODE_DEFAULT;
    fi
    return
}

get_channel () {
    # prompt for psk 
    read -p "Please enter the channel to use for the wireless connection (1-11) [$CHANNEL_DEFAULT] : " CHANNEL
    if [ "$CHANNEL" == "" ]; then 
        CHANNEL=$CHANNEL_DEFAULT;
    fi
    return
}

#####################################################

main () {

  # check that the WLAN Pi is in classic mode
  PI_STATUS=`cat $STATUS_FILE | grep 'classic'` || true
  if  [ -z "$PI_STATUS" ]; then
     cat <<FAIL
####################################################
Failed: WLAN Pi is not in classic mode.
Please switch to classic mode and re-run this script
(exiting...)
#################################################### 
FAIL
     exit 1
  fi

    # set up the wireless connection configuration
    clear
    cat <<INTRO
#####################################################
This script will configure the wireless details for 
the WLAN Pi server mode.

You will need to provide a wireless network interface
name, network name (SSID), shared key and channel 
number. The network name will be the name advertised 
when you flip in to server mode. The key will be used
to secure the wireless connection.

You will also need to provide a two letter country 
code for your geographic region to ensure compliance 
with local regulations (e.g. US, GB, DE, CA etc.)
Only the 2.4GHz band is currently available for the 
wireless connection, so you must choose a channel
between 1 - 11.

(Note: there is no validation of values entered, so
if you enter bad values, things will not work...)
##################################################### 
INTRO

    read -p "Do you wish to continue? (y/n) : " yn

    if [[ ! $yn =~ [yY] ]]; then
        echo "OK, exiting."
        exit 1
    fi

    # Select PSK or PEAP
    clear
    cat <<SEC
#####################################################
            Wireless Configuration
Please enter the network name, network key, country
code and channel number as prompted below (remember,
use appropriate, correct values if you want things 
to work)

(Default values are shown in square brackets and will
be used if no value is entered)
##################################################### 
SEC

    get_interface
    get_ssid
    get_psk
    get_country
    get_channel
    
    echo "Writing supplied configuration values..."

    # hostapd configs
    sed -i "s/^interface=wlan.*/interface=$INTERFACE/" $CONFIG_FILE
    sed -i "s/^ssid=.*$/ssid=$SSID/" $CONFIG_FILE
    sed -i "s/^wpa_passphrase=.*$/wpa_passphrase=$KEY/" $CONFIG_FILE
    sed -i "s/^country_code=.*$/country_code=$COUNTRYCODE/" $CONFIG_FILE
    sed -i "s/^channel=.*$/channel=$CHANNEL/" $CONFIG_FILE

    # dhcpd config
    sed -i "s/^interface wlan.*$/interface $INTERFACE;/" $DHCP_FILE

    # isc-dhcp-server config
    sed -i "s/^INTERFACESv4=.*$/INTERFACESv4=\"usb0 $INTERFACE\ eth0\"/" $ISC_DHCP_FILE

    # interfaces config file
    sed -i "s/^iface wlan.*$/iface $INTERFACE inet static/" $INTERFACES_FILE
    sed -i "s/^allow-hotplug wlan.*$/allow-hotplug $INTERFACE/" $INTERFACES_FILE
    
    echo "Wireless link configured."
    sleep 1


    cat <<COMPLETE
#####################################################
 Quickstart script completed. If the script completed
 with no errors, you may now switch in to server
 mode.

 Would you like me to switch your WLAN Pi in to
 server mode (this will cause a reboot)?

 !!!! NOTE: WHEN SWITCHING TO SERVER MODE , A DHCP
 SERVER IS ENABLED ON THE ETEHRENT PORT. THIS CAN
 CAUSE DISRUPTION ON A LIVE NETWORK !!!!
##################################################### 
COMPLETE
    
    read -p "Would to like switch to server mode? (NOTE WARNING MESSAGE ABOVE!!!) (y/n) : " yn

    case $yn in
        y|Y ) echo "Switching...";;
        *   ) echo "OK, you can switch to server mode later using the front panel buttons. We're all done. Bye!"; exit 0;
    esac

    echo "(After a reboot, the WAN Pi will come back up in server mode.)"
    /usr/sbin/server_switcher on

    return
}

########################
# main
########################
main
exit 0