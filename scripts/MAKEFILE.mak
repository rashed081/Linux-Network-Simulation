.PHONY: all setup bridge link assign route clean

all: setup bridge link assign route

setup:
	sudo ip netns add ns1
	sudo ip netns add ns2
	sudo ip netns add router-ns

bridge: setup
	sudo ip link add br1 type bridge
	sudo ip link set br1 up
	sudo ip link add br2 type bridge
	sudo ip link set br2 up
	sysctl -w net.bridge.bridge-nf-call-iptables=0
    sysctl -w net.bridge.bridge-nf-call-ip6tables=0
    sysctl -w net.bridge.bridge-nf-call-arptables=0

link: bridge
	sudo ip link add veth1 type veth peer name br1-veth1
	sudo ip link set veth1 netns ns1
	sudo ip link set br1-veth1 master br1
	sudo ip link set br1-veth1 up

	sudo ip link add veth2 type veth peer name br2-veth2
	sudo ip link set veth2 netns ns2
	sudo ip link set br2-veth2 master br2
	sudo ip link set br2-veth2 up

	sudo ip link add veth-r1 type veth peer name br1-veth-r
	sudo ip link add veth-r2 type veth peer name br2-veth-r
	sudo ip link set veth-r1 netns router-ns
	sudo ip link set veth-r2 netns router-ns
	sudo ip link set br1-veth-r up
	sudo ip link set br2-veth-r up
	sudo ip link set br1-veth-r master br1
	sudo ip link set br2-veth-r master br2

	sudo ip netns exec ns1 ip link set veth1 up
	sudo ip netns exec ns2 ip link set veth2 up
	sudo ip netns exec router-ns ip link set veth-r1 up
	sudo ip netns exec router-ns ip link set veth-r2 up

assign: link
	sudo ip netns exec ns1 ip addr add 10.0.1.2/24 dev veth1
	sudo ip netns exec ns2 ip addr add 10.0.2.2/24 dev veth2
	sudo ip netns exec router-ns ip addr add 10.0.1.1/24 dev veth-r1
	sudo ip netns exec router-ns ip addr add 10.0.2.1/24 dev veth-r2
	sudo ip addr add 10.0.1.254/24 dev br1
	sudo ip addr add 10.0.2.254/24 dev br2

route: assign
	sudo ip netns exec ns1 ip route flush all
	sudo ip netns exec ns1 ip route add 10.0.1.0/24 dev veth1
	sudo ip netns exec ns1 ip route add default via 10.0.1.1

	sudo ip netns exec ns2 ip route flush all
	sudo ip netns exec ns2 ip route add 10.0.2.0/24 dev veth2
	sudo ip netns exec ns2 ip route add default via 10.0.2.1

	sudo ip netns exec router-ns ip route flush all
	sudo ip netns exec router-ns ip route add 10.0.1.0/24 dev veth-r1
	sudo ip netns exec router-ns ip route add 10.0.2.0/24 dev veth-r2
	

clean:
	sudo ip netns del ns1
	sudo ip netns del ns2
	sudo ip netns del router-ns
	sudo ip link del br1
	sudo ip link del br2