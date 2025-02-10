.PHONY: all setup bridge link assign route clean

NS1=ns1
NS2=ns2
ROUTER=router-ns
BR1=br1
BR2=br2
VETH1=veth1
VETH2=veth2
VETH_R1=veth-r1
VETH_R2=veth-r2
BR1_VETH1=br1-veth1
BR2_VETH2=br2-veth2
BR1_VETH_R=br1-veth-r
BR2_VETH_R=br2-veth-r

all: setup bridge link assign route

setup:
	sudo ip netns add $(NS1)
	sudo ip netns add $(NS2)
	sudo ip netns add $(ROUTER)

bridge:
	sudo ip link add $(BR1) type bridge
	sudo ip link set $(BR1) up
	sudo ip link add $(BR2) type bridge
	sudo ip link set $(BR2) up
	sysctl -w net.bridge.bridge-nf-call-iptables=0
	sysctl -w net.bridge.bridge-nf-call-ip6tables=0
	sysctl -w net.bridge.bridge-nf-call-arptables=0

link:
	sudo ip link add $(VETH1) type veth peer name $(BR1_VETH1)
	sudo ip link set $(VETH1) netns $(NS1)
	sudo ip link set $(BR1_VETH1) master $(BR1)
	sudo ip link set $(BR1_VETH1) up

	sudo ip link add $(VETH2) type veth peer name $(BR2_VETH2)
	sudo ip link set $(VETH2) netns $(NS2)
	sudo ip link set $(BR2_VETH2) master $(BR2)
	sudo ip link set $(BR2_VETH2) up

	sudo ip link add $(VETH_R1) type veth peer name $(BR1_VETH_R)
	sudo ip link add $(VETH_R2) type veth peer name $(BR2_VETH_R)
	sudo ip link set $(VETH_R1) netns $(ROUTER)
	sudo ip link set $(VETH_R2) netns $(ROUTER)
	sudo ip link set $(BR1_VETH_R) up
	sudo ip link set $(BR2_VETH_R) up
	sudo ip link set $(BR1_VETH_R) master $(BR1)
	sudo ip link set $(BR2_VETH_R) master $(BR2)

	sudo ip netns exec $(NS1) ip link set $(VETH1) up
	sudo ip netns exec $(NS2) ip link set $(VETH2) up
	sudo ip netns exec $(ROUTER) ip link set $(VETH_R1) up
	sudo ip netns exec $(ROUTER) ip link set $(VETH_R2) up

assign:
	sudo ip netns exec $(NS1) ip addr add 10.0.1.2/24 dev $(VETH1)
	sudo ip netns exec $(NS2) ip addr add 10.0.2.2/24 dev $(VETH2)
	sudo ip netns exec $(ROUTER) ip addr add 10.0.1.1/24 dev $(VETH_R1)
	sudo ip netns exec $(ROUTER) ip addr add 10.0.2.1/24 dev $(VETH_R2)
	sudo ip addr add 10.0.1.254/24 dev $(BR1)
	sudo ip addr add 10.0.2.254/24 dev $(BR2)

route:
	sudo ip netns exec $(NS1) ip route flush all
	sudo ip netns exec $(NS1) ip route add 10.0.1.0/24 dev $(VETH1)
	sudo ip netns exec $(NS1) ip route add default via 10.0.1.1

	sudo ip netns exec $(NS2) ip route flush all
	sudo ip netns exec $(NS2) ip route add 10.0.2.0/24 dev $(VETH2)
	sudo ip netns exec $(NS2) ip route add default via 10.0.2.1

	sudo ip netns exec $(ROUTER) ip route flush all
	sudo ip netns exec $(ROUTER) ip route add 10.0.1.0/24 dev $(VETH_R1)
	sudo ip netns exec $(ROUTER) ip route add 10.0.2.0/24 dev $(VETH_R2)
	
	sysctl -w net.ipv4.ip_forward=1
    ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1

clean:
	sudo ip netns del $(NS1)
	sudo ip netns del $(NS2)
	sudo ip netns del $(ROUTER)
	sudo ip link del $(BR1)
	sudo ip link del $(BR2)