#!/bin/bash


LOG_FILE="network_setup.log"

log_message() {
    local message="$1"
    echo "[INFO] $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "[ERROR] $message" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

cleanup() {
    log_message "Starting cleanup..."

    ip netns del ns1
    ip netns del ns2
    ip netns del router-ns

    ip link set br0 down
    ip link set br1 down
    ip link del br0
    ip link del br1

    rm -f "$LOG_FILE"

    log_message "Cleanup completed"
}


setup_bridges() {
    log_message "Setting up network bridges..."

    ip link add br0 type bridge|| { log_error "Failed to create br0"; return 1; }
    ip link set br0 up

    ip link add br1 type bridge || { log_error "Failed to create br1"; return 1; }
    ip link set br1 up

    sysctl -w net.bridge.bridge-nf-call-iptables=0
    sysctl -w net.bridge.bridge-nf-call-ip6tables=0
    sysctl -w net.bridge.bridge-nf-call-arptables=0

    log_message "Bridges created successfully"
}

create_namespaces() {
    log_message "Creating network namespaces..."

    ip netns add ns1 || { log_error "Failed to create ns1"; return 1; }
    ip netns add ns2 || { log_error "Failed to create ns2"; return 1; }
    ip netns add router-ns || { log_error "Failed to create router-ns"; return 1; }

    log_message "Network namespaces created successfully"
}


setup_veth_pairs() {
    log_message "Setting up veth pairs..."

    ip link add veth1 type veth peer name br0-veth1 || { log_error "Failed to create veth pair for ns1"; return 1; }
    ip link set veth1 netns ns1
	ip link set br0-veth1 master br0
    ip link set br0-veth1 up

    ip link add veth2 type veth peer name br1-veth2 || { log_error "Failed to create veth pair for ns2"; return 1; }
    ip link set veth2 netns ns2
    ip link set br1-veth2 master br1
    ip link set br1-veth2 up

    ip link add veth-r1 type veth peer name br0-veth-r || { log_error "Failed to create veth pair for router br0"; return 1; }
    ip link add veth-r2 type veth peer name br1-veth-r || { log_error "Failed to create veth pair for router br1"; return 1; }

    ip link set veth-r1 netns router-ns
    ip link set veth-r2 netns router-ns
    ip link set br0-veth-r up
    ip link set br1-veth-r up
    ip link set br0-veth-r master br0
    ip link set br1-veth-r master br1

    ip netns exec ns1 ip link set veth1 up
    ip netns exec ns2 ip link set veth2 up
    ip netns exec router-ns ip link set veth-r1 up
    ip netns exec router-ns ip link set veth-r2 up

    log_message "Veth pairs created successfully"
}

configure_ip_addresses() {
    log_message "Configuring IP addresses..."

    ip netns exec ns1 ip addr add 10.0.1.2/24 dev veth1

    ip netns exec ns2 ip addr add 10.0.2.2/24 dev veth2

    ip netns exec router-ns ip addr add 10.0.1.1/24 dev veth-r1
    ip netns exec router-ns ip addr add 10.0.2.1/24 dev veth-r2

    log_message "IP addresses configured successfully"
}

setup_routing() {
    log_message "Setting up routing..."

    sysctl -w net.ipv4.ip_forward=1
    ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1

    ip netns exec ns1 ip route add 10.0.1.0/24 dev veth1
    ip netns exec ns1 ip route add default via 10.0.1.1

    ip netns exec ns2 ip route add 10.0.2.0/24 dev veth2
    ip netns exec ns2 ip route add default via 10.0.2.1

    ip netns exec router-ns ip route add 10.0.1.0/24 dev veth-r1
    ip netns exec router-ns ip route add 10.0.2.0/24 dev veth-r2

    log_message "Routing configured successfully"
}

test_connectivity() {
    log_message "Testing connectivity..."


    echo "ns1 local interface..."
    ip netns exec ns1 ping -c 2 10.0.1.1

    echo "ns2 local interface..."
    ip netns exec ns2 ping -c 2 10.0.2.1

    echo "ping from ns1 to ns2..."
    ip netns exec ns1 ping -c 3 10.0.2.2

    echo "ping from ns2 to ns1..."
    ip netns exec ns2 ping -c 3 10.0.1.2
}

# Main execution
main() {
    check_root
    cleanup
    setup_bridges || exit 1
    create_namespaces || exit 1
    setup_veth_pairs || exit 1
    configure_ip_addresses || exit 1
    setup_routing || exit 1

    test_connectivity

    log_message "Network setup completed successfully"
    echo "Use 'sudo ./$(basename "$0") cleanup' to clean up the configuration"
}

if [ "$1" = "cleanup" ]; then
    cleanup
    exit 0
fi

main