# Base image
FROM alpine:3.18

# Install required packages
RUN apk --no-cache add bash curl iptables ip6tables openvpn easy-rsa

# Set environment variables for EasyRSA
ENV EASYRSA="/usr/share/easy-rsa"
ENV OVPN_DIR="/etc/openvpn"

# Copy scripts and configuration
COPY bin /opt/app/bin
COPY docker-entrypoint.sh /opt/app/docker-entrypoint.sh
COPY config/easy-rsa.vars /etc/openvpn/config/easy-rsa.vars

# Make scripts executable
RUN chmod +x /opt/app/bin/* /opt/app/docker-entrypoint.sh \
    && mkdir -p /opt/app/clients /opt/app/pki /opt/app/config /opt/app/log

# Expose UDP port for OpenVPN
EXPOSE 1194/udp

# Set entrypoint
ENTRYPOINT ["/opt/app/docker-entrypoint.sh"]
