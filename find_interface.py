import subprocess
import re

# Obtenir les interfaces réseau
interfaces = subprocess.check_output(["ifconfig", "-a"]).decode().split("\n\n")
connection = []

# Parcourir les interfaces et extraire les adresses IP
for iface in interfaces:
    iface_info = {}
    lines = iface.strip().split("\n")
    iface_name = lines[0].split(":")[0]
    if iface_name == "lo":
        continue  # Ignorer l'interface "lo"
    iface_info["interface"] = iface_name
    for line in lines:
        match = re.search(r"inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})", line)
        if match:
            iface_info["ip"] = match.group(1)
    if "ip" in iface_info:
        connection.append(iface_info)

# Écrire les interfaces et leurs adresses IP dans un fichier temporaire
with open("/tmp/interfaces.txt", "w") as file:
    for iface in connection:
        file.write(f"Interface: {iface['interface']}\n")
        file.write(f"IP: {iface['ip']}\n")
