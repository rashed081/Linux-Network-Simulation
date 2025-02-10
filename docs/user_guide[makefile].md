
# Makefile User Guide

## Available Targets

  

### 1. Complete Setup

```bash
sudo  make  all
```

Executes all targets in sequence:

- Creates namespaces

- Sets up bridges

- Creates and configures links

- Assigns IP addresses

- Configures routing

### 2. Individual Targets

#### Create Network Namespaces

```bash
sudo  make  setup
```

Creates three network namespaces:

- ns1

- ns2

- router-ns

  

#### Configure Network Bridges

```bash
sudo  make  bridge
```

- Creates and activates br1 and br2

- Disables bridge-netfilter settings


#### Create Network Links

```bash
sudo  make  link
```

Creates and configures virtual ethernet pairs:

- ns1 <-> br1

- ns2 <-> br2

- router-ns <-> br1 and br2
 

#### Assign IP Addresses

```bash
sudo  make  assign
```

Configures IP addresses:

- ns1: 10.0.1.2/24

- ns2: 10.0.2.2/24

- router-ns: 10.0.1.1/24, 10.0.2.1/24

- br1: 10.0.1.254/24

- br2: 10.0.2.254/24

  

#### Configure Routing

```bash
sudo  make  route
```

Sets up routing tables:

- Configures default routes

- Sets up network routes

- Enables packet forwarding

  

#### Clean Environment

```bash
sudo  make  clean
```

Removes all created components:

- Deletes network namespaces

- Removes bridge interfaces

- Cleans up virtual interfaces

  

## Network Details

  

### IP Addressing Scheme

```

Network 1 (10.0.1.0/24):

- ns1: 10.0.1.2

- router-ns (veth-r1): 10.0.1.1

- br1: 10.0.1.254

  

Network 2 (10.0.2.0/24):

- ns2: 10.0.2.2

- router-ns (veth-r2): 10.0.2.1

- br2: 10.0.2.254

```

  

### Network Topology

```

ns1 (10.0.1.2) --- br1 (10.0.1.0) --- router-ns (10.0.1.1, 10.0.2.1) --- br2 (10.0.2.0) --- ns2 (10.0.2.2)

```

  

## Usage Examples

  

### Complete Setup

```bash

# Clean any existing setup and create new environment

sudo  make  clean

sudo  make  all

```

  

### Step-by-Step Setup

```bash

# Create components one by one

sudo  make  setup

sudo  make  bridge

sudo  make  link

sudo  make  assign

sudo  make  route

```

  

### Verify Configuration

```bash

# Check network namespaces

ip  netns  list

# Check bridges

ip  link  show  type  bridge  

# Verify IP addresses

ip  netns  exec  ns1  ip  addr  show

ip  netns  exec  ns2  ip  addr  show

ip  netns  exec  router-ns  ip  addr  show

```

  

## Common Issues

  

1.  **Permission Denied**

```bash

# Always use sudo

sudo make <target>

```

  

2.  **Resource Already Exists**

```bash

# Clean first

sudo make clean

```

  



  

3.  **Network Unreachable**

```bash

# Check routing tables

ip netns exec ns1 ip route

ip netns exec ns2 ip route

ip netns exec router-ns ip route

```

  

## Troubleshooting Commands

  

### Check Network Status

```bash

# List network namespaces

ip  netns  list  

# Show bridge interfaces

ip  link  show  type  bridge  

# Check routing tables

ip  netns  exec  router-ns  ip  route  show

```

  

### Verify Connectivity

```bash

# Test from ns1 to ns2

sudo  ip  netns  exec  ns1  ping  10.0.2.2  

# Test from ns2 to ns1

sudo  ip  netns  exec  ns2  ping  10.0.1.2

```

  



  

