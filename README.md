# Linux-Network-Simulation


+------------+
| router-ns |
| 10.0.1.1/24|
| 10.0.2.1/24|
+------------+
/ \
/ \
veth-r1 veth-r2
/ \
/ \
br0 br1
| |
| |
veth1 veth2
| |
+----------+ +----------+
| ns1 | | ns2 |
|10.0.1.2/24| |10.0.2.2/24|
+----------+ +----------+
