#!/bin/bash

# Exit on any error
set -e

# Variables
REDSOCKS_CONF="/etc/redsocks.conf"
IPTABLES_RULES="/etc/iptables/rules.v4"

# Step 1: Stop redsocks
echo "Stopping redsocks..."
systemctl stop redsocks || true
systemctl disable redsocks || true

# Step 2: Uninstall redsocks and iptables-persistent
echo "Uninstalling redsocks and iptables-persistent..."
apt purge -y redsocks iptables-persistent
apt autoremove -y

# Step 3: Remove redsocks configuration
echo "Removing redsocks configuration..."
if [ -f "$REDSOCKS_CONF" ]; then
    rm -f "$REDSOCKS_CONF"
fi
if [ -f "/var/log/redsocks.log" ]; then
    rm -f "/var/log/redsocks.log"
fi

# Step 4: Flush and reset iptables
echo "Resetting iptables..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Remove iptables rules file
if [ -f "$IPTABLES_RULES" ]; then
    rm -f "$IPTABLES_RULES"
fi

# Step 5: Verify cleanup
echo "Verifying cleanup..."
if ! command -v redsocks &> /dev/null; then
    echo "Redsocks successfully uninstalled."
else
    echo "Warning: Redsocks binary still present."
fi

if iptables -t nat -L -v -n | grep -q "Chain REDSOCKS"; then
    echo "Warning: REDSOCKS iptables chain still exists."
else
    echo "iptables rules successfully reset."
fi

echo "Cleanup complete. All redsocks and iptables configurations have been removed."
echo "If you disabled IPv6, you can re-enable it with: sysctl -w net.ipv6.conf.all.disable_ipv6=0"
