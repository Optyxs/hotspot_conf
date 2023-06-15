sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install hostapd -y
sudo apt-get install dnsmasq -y
sudo apt-get install bridge-utils -y
sudo apt-get install iptables -y
sudo apt-get install python -y

sudo chmod +x hostapd_script.sh
sudo chmod +x rc.local

read -p "Do you want to see an ifconfig to see your active interface? (y/n) " answer

if [ "$answer" = "y" ]; then
    sudo ifconfig -s
fi

read -p "Choose wifi interface for hotspot: " val_wifi
sudo sed -i "s/interface=wlan0/interface=$val_wifi/" hostapd.conf

read -p "Choose ssid name : " val
sudo sed -i "s/ssid=relay/ssid=$val/" hostapd.conf

read -p "Choose password for hotspot : " val
sudo sed -i "s/wpa_passphrase=optyxs44/wpa_passphrase=$val/" hostapd.conf

sudo python3 find_interface.py

if [ -s "/tmp/interfaces.txt" ]; then
    sudo cat /tmp/interfaces.txt
    read -p "Choose interface with valid internet to broadcast : " val_source
    sudo sed -i "s/brctl addif br0 eth0 wlan0/brctl addif br0 $val_source $val_wifi/" hostapd_script.sh
    ip_address=$(grep -A 1 "Interface: $val_source" /tmp/interfaces.txt | grep "IP:" | awk '{print $2}')
    subnet_mask=$(ip route | awk "/$ip_address/ { print \$1 }")
    modified_ip=$(echo "$ip_address" | cut -d. -f1-3)
    sudo sed -i "s/ifconfig wlan0 192.168.2.2 netmask 255.255.255.0 up/ifconfig $val_wifi 192.168.2.2 netmask 255.255.255.0 up/" hostapd_script.sh
    sudo sed -i "s/192.168.1.0\/24/$modified_ip.0\/24/" hostapd_script.sh
    sudo sed -i "s|ifconfig eth0 192\.168\.1\.13 netmask 255\.255\.255\.0 up|ifconfig $val_source $ip_address netmask $subnet_mask up|" hostapd_script.sh
    sudo awk '{ sub(/ifconfig br0 192\.168\.1\.2 netmask 255\.255\.255\.0/, "ifconfig br0 " $modified_ip ".2 netmask " $subnet_mask); print }' hostapd_script.sh > hostapd_script.tmp && sudo mv hostapd_script.tmp hostapd_script.sh
    sudo awk '{ sudo sed -i "s|dhcp-range=192\.168\.1\.3,192\.168\.1\.100,255\.255\.255\.0,12h|dhcp-range='$modified_ip.3,$modified_ip.100,$subnet_mask,12h'|" dnsmasq.conf
    answer=""
    read -p "Do you want to rm wpa_supplicant.conf ? (y/n) " answer
    if [ "$answer" = "y" ]; then
        sudo rm /etc/wpa_supplicant/wpa_supplicant.conf
    fi
else
    echo "No valid interface, are you sure you are connected to the internet?"
    echo "Exiting without installing"
    exit
fi

sudo cp dnsmasq.conf /etc/dnsmasq.conf
sudo cp hostapd_script.sh /etc/init.d/hostapd-script.sh
sudo cp rc.local /etc/rc.local
sudo cp hostapd.conf /etc/hostapd/hostapd.conf

read -p "Done installing. You should reboot. Do you wish to reboot? (y/n)" answer

if [ "$answer" = "y" ]; then
    sudo reboot
fi
