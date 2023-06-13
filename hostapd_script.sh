
#!/bin/bash

# Switch to tty2
chvt 2

# Start hostapd in the background using the 'fork' option
hostapd  /etc/hostapd/hostapd.conf > /dev/null 2>&1 &

# Create network bridge
brctl addbr br0
brctl addif br0 eth0 wlan0

# Enable the bridge
ifconfig eth0 192.168.1.13 netmask 255.255.255.0 up
ifconfig wlan0 192.168.2.2 netmask 255.255.255.0 up
ifconfig br0 192.168.1.2 netmask 255.255.255.0

# Enable IP forwarding
sysctl net.ipv4.ip_forward=1 &

# Enable NAT routing
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE &

# Switch back to tty1
chvt 1
