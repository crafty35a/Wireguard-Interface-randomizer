
#!/usr/bin/env bash

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# we don't want to continue execution of the script if something is broken. This may potentially
# complicate IP routing table entries which may require manual intervention to fix thereafter.
set -e

# Declare global variables here
# Modify the variables in this section in conformity with the naming convention of your Mullvad
# configuration files in /etc/wireguard
mullvadVpnInterfaceRegex="mullvad-\w*"
wireguardConfigurationDirectory="/etc/wireguard/"
connectedWireguardConfiguration=""

# I don't use this, my interface will always be wg0
# A method to retrieve the current connected Mullvad interface.
# checkMullvadConnectivity() {
#         # Check if Mullvad VPN is already connected.
#         connectedWireguardConfiguration=$(ip addr | grep --word-regexp "$1" | cut -d " " -f 2 | tr -d ":")
#         # Return an arbitrary integer value | This value is not checked right now
#         return 0
# }

#checkMullvadConnectivity "$mullvadVpnInterfaceRegex"

# Debug log
# echo " ip addr command returned $connectedWireguardConfiguration"

# Extract the wireguard configuration list that is available in /etc/wireguard
newWireguardConfigurationList=$(sudo ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex")

printf "" # Blank space for formatting
printf "Randomizing the Mullvad VPN Connection..."

#Check if wg0.conf exists
if sudo [ ! -f /etc/wireguard/wg0.conf ]
then
        printf "wg0.conf doesn't exist yet (first time run)\n"
	
        # Pick a wireguard interface at random to connect to next
        newWireguardConfiguration=$(shuf -n 1 -e $newWireguardConfigurationList)

	# Rename randomly selected server to wg0
        sudo mv /etc/wireguard/"$newWireguardConfiguration" /etc/wireguard/wg0.conf
	
	# Write selected server name to lastServer.txt
	printf "$newWireguardConfiguration" | sudo tee lastServer.txt  # add -a for append (>>)

else
        sudo printf "wg0.conf already exists"
	
        # Pick a wireguard interface at random to connect to next
        newWireguardConfiguration=$(shuf -n 1 -e $newWireguardConfigurationList)
	
	# Read last connected server from lastServer.txt
        lastConnectedInterface=$(<lastServer.txt)

	# Rename wg0.conf (last connected server) back to actual server name
        sudo mv /etc/wireguard/wg0.conf /etc/wireguard/"$lastConnectedInterface".conf	
	# Rename randomly selected server to wg0.conf
        sudo mv /etc/wireguard/"$newWireguardConfiguration" /etc/wireguard/wg0.conf

	# Write selected server name to lastServer.txt
	printf "$newWireguardConfiguration" | sudo tee lastServer.txt  # add -a for append (>>)

fi

printf "Disconnecting from WireGuard (if tunnel was up)\n"
sudo wg-quick down wg0 #2> /dev/null
printf "Reconnecting to new WireGuard server\n"
sudo wg-quick up wg0 #2> /dev/null
