#!/bin/bash


LOG_FILE="network_setup.log"

NS1="ns1"
NS2="ns2"
ROUTER="router-ns"
BR1="br1"
BR2="br2"
VETH1="veth1"
VETH2="veth2"
VETH_R1="veth-r1"
VETH_R2="veth-r2"
BR1_VETH1="br1-veth1"
BR2_VETH2="br2-veth2"
BR1_VETH_R="br1-veth-r"
BR2_VETH_R="br2-veth-r"

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

    ip netns del $NS1
    ip netns del $NS2
    ip netns del $ROUTER

    ip link set $BR1 down
    ip link set $BR2 down
    ip link del $BR1
    ip link del $BR2

    rm -f "$LOG_FILE"

    log_message "Cleanup completed"
}


setup_bridges() {
    log_message "Setting up network bridges..."

    ip link add $BR1 type bridge || { log_error "Failed to create $BR1"; return 1; }
    ip link set $BR1 up

    ip link add $BR2 type bridge || { log_error "Failed to create $BR2"; return 1; }
    ip link set $BR2 up

    sysctl -w net.bridge.bridge-nf-call-iptables=0
    sysctl -w net.bridge.bridge-nf-call-ip6tables=0
    sysctl -w net.bridge.bridge-nf-call-arptables=0

    log_message "Bridges created successfully"
}

create_namespaces() {
    log_message "Creating network namespaces..."

    ip netns add $NS1 || { log_error "Failed to create $NS1"; return 1; }
    ip netns add $NS2 || { log_error "Failed to create $NS2"; return 1; }
    ip netns add $ROUTER || { log_error "Failed to create $ROUTER"; return 1; }

    log_message "Network namespaces created successfully"
}


setup_veth_pairs() {
    log_message "Setting up veth pairs..."

    ip link add $VETH1 type veth peer name $BR1_VETH1 || { log_error "Failed to create veth pair for $NS1"; return 1; }
    ip link set $VETH1 netns $NS1
    ip link set $BR1_VETH1 master $BR1
    ip link set $BR1_VETH1 up

    ip link add $VETH2 type veth peer name $BR2_VETH2 || { log_error "Failed to create veth pair for $NS2"; return 1; }
    ip link set $VETH2 netns $NS2
    ip link set $BR2_VETH2 master $BR2
    ip link set $BR2_VETH2 up

    ip link add $VETH_R1 type veth peer name $BR1_VETH_R || { log_error "Failed to create veth pair for $ROUTER $BR1"; return 1; }
    ip link add $VETH_R2 type veth peer name $BR2_VETH_R || { log_error "Failed to create veth pair for $ROUTER $BR2"; return 1; }

    ip link set $VETH_R1 netns $ROUTER
    ip link set $VETH_R2 netns $ROUTER
    ip link set $BR1_VETH_R up
    ip link set $BR2_VETH_R up
    ip link set $BR1_VETH_R master $BR1
    ip link set $BR2_VETH_R master $BR2

    ip netns exec $NS1 ip link set $VETH1 up
    ip netns exec $NS2 ip link set $VETH2 up
    ip netns exec $ROUTER ip link set $VETH_R1 up
    ip netns exec $ROUTER ip link set $VETH_R2 up

    log_message "Veth pairs created successfully"
}

configure_ip_addresses() {
    log_message "Configuring IP addresses..."

    ip netns exec $NS1 ip addr add 10.0.1.2/24 dev $VETH1
    ip netns exec $NS2 ip addr add 10.0.2.2/24 dev $VETH2
    ip netns exec $ROUTER ip addr add 10.0.1.1/24 dev $VETH_R1
    ip netns exec $ROUTER ip addr add 10.0.2.1/24 dev $VETH_R2

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