#!/bin/bash
set -e

EASYRSA="/usr/share/easy-rsa"
OVPN_DIR="/etc/openvpn"
CLIENT_NAME="client1"

# Initialize PKI if not exists
if [ ! -d "$EASYRSA/pki" ]; then
    echo "Initializing PKI..."
    $EASYRSA/easyrsa init-pki
fi

# Build CA if not exists
if [ ! -f "$EASYRSA/pki/ca.crt" ]; then
    echo "Building CA..."
    cd $EASYRSA
    ./easyrsa --batch build-ca nopass
fi

# Build Server Certificate
if [ ! -f "$EASYRSA/pki/issued/server.crt" ]; then
    echo "Building Server Certificate..."
    cd $EASYRSA
    ./easyrsa build-server-full server nopass
    ./easyrsa gen-dh
    openvpn --genkey --secret $OVPN_DIR/ta.key
fi

# Build Client Certificate
cd $EASYRSA
if [ ! -f "$EASYRSA/pki/issued/$CLIENT_NAME.crt" ]; then
    echo "Building Client Certificate..."
    ./easyrsa build-client-full $CLIENT_NAME nopass
fi

# Generate client.ovpn
CLIENT_OVPN="/opt/app/clients/$CLIENT_NAME.ovpn"
if [ ! -f "$CLIENT_OVPN" ]; then
    echo "Generating client.ovpn..."
    cat > $CLIENT_OVPN <<EOL
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1
verb 3

<ca>
$(cat $EASYRSA/pki/ca.crt)
</ca>
<cert>
$(cat $EASYRSA/pki/issued/$CLIENT_NAME.crt)
</cert>
<key>
$(cat $EASYRSA/pki/private/$CLIENT_NAME.key)
</key>
<tls-auth>
$(cat $OVPN_DIR/ta.key)
</tls-auth>
EOL
fi

# Start OpenVPN server
echo "Starting OpenVPN server..."
openvpn --config $OVPN_DIR/server.conf
