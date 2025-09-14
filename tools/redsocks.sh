#!/bin/bash

# Ensure root privileges
sudo -i

# Exit on any error
set -e

# Variables
SOCKS5_SERVER="192.168.10.45"
SOCKS5_PORT="7744"
REDSOCKS_PORT="12345"
REDSOCKS_CONF="/etc/redsocks.conf"
IPTABLES_RULES="/etc/iptables/rules.v4"

# Step 1: Install redsocks
echo "Installing redsocks..."
apt update
apt install -y redsocks iptables-persistent

# Step 2: Configure redsocks
echo "Configuring redsocks..."
cat > $REDSOCKS_CONF << EOL
base {
    log_debug = off;
    log_info = on;
    log = "file:/var/log/redsocks.log";
    daemon = on;
    redirector = iptables;
}
redsocks {
    local_ip = 127.0.0.1;
    local_port = $REDSOCKS_PORT;
    ip = $SOCKS5_SERVER;
    port = $SOCKS5_PORT;
    type = socks5;
}
EOL

# Step 3: Start redsocks
echo "Starting redsocks..."
systemctl stop redsocks || true
systemctl enable redsocks
systemctl start redsocks

# Step 4: Configure iptables
echo "Configuring iptables..."
# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Create new chain for proxy redirection
iptables -t nat -N REDSOCKS

# Skip redirection for redsocks itself and the SOCKS5 server
iptables -t nat -A REDSOCKS -d $SOCKS5_SERVER -j ACCEPT
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j ACCEPT
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j ACCEPT

# Redirect TCP traffic to redsocks
iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports $REDSOCKS_PORT

# Apply REDSOCKS chain to OUTPUT for non-root users
iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

# Redirect DNS traffic (UDP port 53) to redsocks (socks5h implies proxy DNS)
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports $REDSOCKS_PORT

# Save iptables rules
echo "Saving iptables rules..."
iptables-save > $IPTABLES_RULES

# Step 5: Verify setup
echo "Verifying redsocks is running..."
if systemctl is-active --quiet redsocks; then
    echo "Redsocks is running."
else
    echo "Error: Redsocks failed to start. Check /var/log/redsocks.log."
    exit 1
fi

echo "Setup complete. Testing proxy..."
# Test with curl as non-root user
sudo -u nobody curl --socks5-hostname 127.0.0.1:$REDSOCKS_PORT https://api.ipify.org || {
    echo "Error: Proxy test failed. Check redsocks and SOCKS5 server connectivity."
    exit 1
}

echo "All traffic is now routed through socks5h://$SOCKS5_SERVER:$SOCKS5_PORT"
echo "To verify DNS, visit https://dnsleaktest.com"
echo "To stop redsocks: systemctl stop redsocks"
echo "To flush iptables: iptables -F; iptables -t nat -F; iptables -X; iptables -t nat -X"