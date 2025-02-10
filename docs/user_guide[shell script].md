# Network Namespace Simulation - User Guide

  

## Prerequisites

  

Before using the script, ensure you have:

1. A Linux system with root privileges

2. Required packages installed:

```bash

sudo apt-get update

sudo apt-get install bridge-utils iptables iproute2

```

  

## Installation

  

1. Clone the repository:

```bash

git clone https://github.com/rashed081/Linux-Network-Simulation.git 
or 
git clone git@github.com:rashed081/Linux-Network-Simulation.git

cd Linux-Network-Simulation

```

  

2. Make the script executable:

```bash

chmod +x scripts/network_simulation.sh

```

  

## Basic Usage

  

### Starting the Simulation

  

1. Run the script with root privileges:

```bash

sudo ./scripts/network_namespace_setup.sh

```

  

2. The script will:

	- Create network namespaces (ns1, ns2, router-ns)

	- Set up network bridges (br0, br1)

	- Configure virtual ethernet pairs

	- Set up IP addressing and routing

	- Perform connectivity tests

  

### Cleaning Up

  

To remove all created network components:

```bash

sudo  ./scripts/network_simulation.sh  cleanup

```

  

## Verification Steps

  

### 1. Check Network Namespaces

```bash

# List all network namespaces

ip  netns  list

# Expected output:

ns1

ns2

router-ns

```

  

### 2. Verify Network Interfaces

```bash

# Check interfaces in ns1

sudo  ip  netns  exec  ns1  ip  addr  show

# Check interfaces in ns2

sudo  ip  netns  exec  ns2  ip  addr  show

# Check interfaces in router-ns

sudo  ip  netns  exec  router-ns  ip  addr  show

```

  

### 3. Test Connectivity

  

#### Local Network Tests

```bash

# From ns1 to router

sudo  ip  netns  exec  ns1  ping  -c  2  10.0.1.1


# From ns2 to router

sudo  ip  netns  exec  ns2  ping  -c  2  10.0.2.1

```

  

#### Cross-Network Tests

```bash

# From ns1 to ns2

sudo  ip  netns  exec  ns1  ping  -c  3  10.0.2.2

# From ns2 to ns1

sudo  ip  netns  exec  ns2  ping  -c  3  10.0.1.2

```

  

## Troubleshooting

  

### Common Issues

  

1.  **Script Permission Error**

```bash

# Fix with:

chmod +x scripts/network_namespace_setup.sh

```

  

2.  **Root Privileges Required**

```bash

# Run with sudo:

sudo ./scripts/network_simulation.sh

```

  

3.  **Resource Busy Error**

```bash

# Clean up first:

sudo ./scripts/network_simulation.sh cleanup

```

  

### Verification Commands

  

1.  **Check Bridge Status**

```bash

brctl show

```

  

2.  **View Routing Tables**

```bash

# In ns1

sudo ip netns exec ns1 ip route

# In ns2

sudo ip netns exec ns2 ip route

# In router-ns

sudo ip netns exec router-ns ip route

```

  

3.  **Check IP Forwarding**

```bash

# In host

cat /proc/sys/net/ipv4/ip_forward

# In router-ns

sudo ip netns exec router-ns cat /proc/sys/net/ipv4/ip_forward

```

  

## Network Details

  

### IP Addressing Scheme

- Network 1 (10.0.1.0/24):

	- ns1: 10.0.1.2

	- router-ns: 10.0.1.1

  

- Network 2 (10.0.2.0/24):

	- ns2: 10.0.2.2

	- router-ns: 10.0.2.1

  

### Network Topology

```

ns1 (10.0.1.2) --- br0 --- router-ns (10.0.1.1, 10.0.2.1) --- br1 --- ns2 (10.0.2.2)

```

  

## Advanced Usage

  

### Manual Interface Configuration

  

1.  **Enter a Namespace**

```bash

sudo ip netns exec ns1 bash

```

  

2.  **Configure Interface Manually**

```bash

# Inside namespace

ip addr add 10.0.1.2/24 dev veth1

ip link set veth1 up

ip route add default via 10.0.1.1

```

  

### Monitoring Traffic

  

 **Monitor with tcpdump**

```bash

# Install tcpdump

sudo apt-get install tcpdump

# Monitor traffic in ns1

sudo ip netns exec ns1 tcpdump -i veth1

```

  

## Log Files

  

The script generates a log file: `network_setup.log`
```bash

# View logs

cat  network_setup.log

# Monitor logs in real-time

tail  -f  network_setup.log

```

  



  

