# A3: IPv6



## 0 Introduction



> Additional reading:
>
> - [RFC 4291](http://ftp.funet.fi/rfc/rfc4291.txt) - IP version 6 Addressing Architecture
> - [RFC 4193](http://ftp.funet.fi/rfc/rfc4193.txt) - Unique Local IPv6 Unicast Addresses
> - [RFC 2375](http://ftp.funet.fi/rfc/rfc2375.txt) - IPv6 Multicast Address Assignment
> - [RFC 2460](http://ftp.funet.fi/rfc/rfc2460.txt) - Internet Protocol, Version 6 (IPv6) Specification
> - [RFC 2461](http://ftp.funet.fi/rfc/rfc2461.txt) - Neighbor Discovery for IP version 6 (IPv6)
> - [Linux 6RD HOWTO](http://www.litech.org/6rd/)
> - [Chapter 10. Configuring IPv4-in-IPv6 tunnels](https://tldp.org/HOWTO/Linux+IPv6-HOWTO/ch10.html)



### 0.1 Motivation

Communication over the internet is done using IP-addresses. IPv4 addresses consist of 32 bits divided into 8 bit segments, and in a common form represented using decimal numbers, e.g. 172.217.21.142. However, with 32 bits it is theoretically possible to have roughly 4,3 billion distinct addresses (232). This doesn’t provide enough addresses to have even a single distinct address for every human in existence. Furthermore, with people having multiple devices connected to the Internet, from mobile phones to air conditioners, many regional internet registries have depleted their pool of IPv4 addresses.

This problem was anticipated however, and IPv6 protocol was developed. With 128 bit long addresses, a vast amount of 3.4*1038 (2128) addresses can be used and divided between the world. Currently, both protocols are used simultaneously, with IPv4 addresses being used for the foreseeable future. While there has been transition to IPv6 for over a decade, the protocols are not compatible with each other, and therefore IPv4-only hardware would need to be completely replaced to fully migrate into IPv6.



### 0.2 Description of the exercise

In this exercise you will familiarize yourself with Internet Protocol version 6 (IPv6). The main task is to build a small network and assign addresses and routes automatically with router advertisements. Finally you will connect your IPv6 network to the global IPv6 internet using Teredo.



## 1 IPv6 addressing 

IPv6 addresses may look more foreign to many people, due to being more complex than IPv4 addresses, even though they have been in use for a long time. You can think in your case, which is the more familiar loopback address: 127.0.0.1 or ::1 (0:0:0:0:0:0:0:1 or even more verbose 0000:0000:0000:0000:0000:0000:0000:0001). 



### 1.1  In *Unique Local IPv6 Unicast Address space*. how does a device know whether the IPv6 address it just created for itself is unique?

It is a process called Duplicate Address Detection(DAD), which is to enable node to determine that an address it wishes to use is not already in use by another node. More specifically, it is realized by Neighbor Discovery (Sending Neighbor Solicitation messages).



### 1.2 Explain 3 methods of dynamically allocating IPv6 global unicast addresses?

Three methods of dynamically allocating IPv6 global unicast addresses are:

- **Stateless Address Autoconfiguration (SLAAC)**: devices can automatically generate a unique global unicast address, without the need for a central server, by combining the network prefix information provided by a Router Advertisement (RA) message with the interface identifier of the device.
- **Dynamic Host Configuration Protocol version 6 (DHCPv6)**: similar to DHCP for IPv4, DHCPv6 allows a centralized server to assign unique global unicast addresses to devices on a network.
- **Stateful Address Autoconfiguration (DHCPv6-Stateful)**: a combination of SLAAC and DHCPv6, where DHCPv6 servers provide the network prefix information, while devices generate their own interface identifier.



## 2 Build two IPv6 networks with a router

To prepare for creating the final network, you will first familiarize yourself with routing messages between two IPv6 networks.

You will set up **lab1** to act as a router. This means that lab1 will route traffic from one network to another. In practice this is done using routing tables, but before that you must allow certain things that are not allowed by default. Use the following sysctl commands (note that the last one will avoid messing up enp0s3 interface. You should do the last one on all of your VMs to prevent problems with misconfiguration.):

```
sudo sysctl -w net.ipv6.conf.default.forwarding=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.enp0s3.accept_ra=0
```

Assign static IPv6 addresses from the subnets *fd01:2345:6789:abc1::/64 and fd01:2345:6789:abc2::/64* to your virtual machines. On lab2 and lab3 add IPv6 route to the other network using lab1 as a gateway. Make sure that you can ping lab1 from lab2 and lab3, then ensure that IPv6 routing works on lab1 by pinging lab3 from lab2. You can also try traceroute to see the route taken by the packets.

You can do the configurations using ip(8). **Editing /etc/network/interfaces is a bad idea** as it can mess radvd in the next part. The addresses should be assigned to intnet interfaces, not the NAT Network.



### 2.1 What do the above sysctl commands do?

- `net.ipv6.conf.default.forwarding=1`:  enable IPv6 forwarding on the default configuration 
- `net.ipv6.conf.all.forwarding=1`: enable IPv6 forwarding on all interfaces 
- `net.ipv6.conf.enp0s3.accept_ra=0`: disables router advertisement acceptance on the interface enp0s3 to prevent misconfiguration, so that the automatical allocation of Ipv6 address is avoided



### 2.2 The subnets used belong to *Unique Local IPv6 Unicast Address space*. Explain what this means and what is the format of such addresses.

It is intended for local communications, usually inside of a site.  These addresses are not expected to be routable on the global Internet.

Format of the addresses:

```
      | 7 bits |1|  40 bits   |  16 bits  |          64 bits           |
      +--------+-+------------+-----------+----------------------------+
      | Prefix |L| Global ID  | Subnet ID |        Interface ID        |
      +--------+-+------------+-----------+----------------------------+
```

- Prefix: FC00::/7 prefix to identify Local IPv6 unicastaddresses.
- L 
  - Set to 1 if the prefix is locally assigned.
  - Set to 0 may be defined in the future.  
- Global ID: 40-bit global identifier used to create a globally unique prefix.  
- Subnet ID: 16-bit Subnet ID is an identifier of a subnet within the site.
- Interface ID: 64-bit Interface ID as defined in [ADDARCH].



### 2.3  List all commands that you used to add static addresses to lab1, lab2 and lab3. Explain one of the add address commands.

On lab1:
```bash
# adds an IPv6 address to the specific device, with a subnet prefix of 64
sudo ip -6 addr add fd01:2345:6789:abc1::1/64 dev enp0s8
sudo ip -6 addr add fd01:2345:6789:abc2::1/64 dev enp0s9
```

On lab2:
```bash
sudo ip -6 addr add fd01:2345:6789:abc1::2/64 dev enp0s8
```

On lab3:

```bash
sudo ip -6 addr add fd01:2345:6789:abc2::2/64 dev enp0s8
```



### 2.4  Show the command that you used to add the route to lab3 on lab2, and explain it.

On lab2:
```bash
sudo ip -6 route add fd01:2345:6789:abc2::/64 via fd01:2345:6789:abc1::1 dev enp0s8
```

The command adds a route for the IPv6 subnet `fd01:2345:6789:abc2::/64` to the device enp0s8. The route uses `fd01:2345:6789:abc1::1` as the gateway (specified with the via option), meaning that packets destined for the address `fd01:2345:6789:abc2::2` (lab3) will be sent to `fd01:2345:6789:abc1::1`(lab1) for forwarding

On lab3:

```bash
sudo ip -6 route add fd01:2345:6789:abc1::/64 via fd01:2345:6789:abc2::1 dev enp0s8
```

Similar.



### 2.5  Show enp0s8 interface information from lab2, as well as the IPv6 routing table. Explain the IPv6 information from the interface and the routing table. What does a double colon (::) indicate?

Command:
```bash
ip -6 addr show dev enp0s8
```

Result:
```
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet6 fd01:2345:6789:abc1::2/64 scope global
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe50:a334/64 scope link
       valid_lft forever preferred_lft forever
```

- `3: enp0s8`: interface index and name.
- `<BROADCAST,MULTICAST,UP,LOWER_UP>`:  flags that indicate the state of the interface. 
  - "UP" means that the interface is active and running.
  - "BROADCAST" and "MULTICAST" indicate that the interface supports broadcast and multicast, respectively. 
  - "LOWER_UP" means that the lower-level protocol is running and the interface is up.
- `mtu 1500`: the maximum transmission unit (MTU) of the interface, which is the maximum size of a single packet that can be transmitted over the network.
- `qdisc fq_codel`: queueing discipline (qdisc) used by the interface. "fq_codel" is a specific type of qdisc that uses the Fair Queuing Codel algorithm for managing network traffic.
- `state UP`: state of the interface, indicating whether it is up (active) or down (inactive).
- `group default`: name of the group to which the interface belongs.
- `qlen 1000`: the maximum number of packets that can be queued for transmission on the interface.
- `inet6 fd01:2345:6789:abc1::2/64`: an IPv6 address assigned to the interface, in CIDR notation. The address is "fd01:2345:6789:abc1::2" and the subnet mask is "/64".
- `scope global`: the scope of the IPv6 address, indicating the portion of the network in which the address is valid. In this case, the scope is "global", meaning that the address can be used on the entire internet.
- `valid_lft forever`: the valid lifetime of the IPv6 address, indicating how long the address will remain assigned to the interface. In this case, the lifetime is "forever", meaning that the address will remain assigned indefinitely.
- `preferred_lft forever:` the preferred lifetimeof the IPv6 address, indicating how long the address will be the preferred address for the interface. In this case, the lifetime is "forever", meaning that the address will be the preferred address indefinitely.

Command:

```bash
ip -6 route
```

Result:
```
::1 dev lo proto kernel metric 256 pref medium
fd01:2345:6789:abc1::/64 dev enp0s8 proto kernel metric 256 pref medium
fd01:2345:6789:abc2::/64 via fd01:2345:6789:abc1::1 dev enp0s8 metric 1024 pref medium
fe80::/64 dev enp0s3 proto kernel metric 256 pref medium
fe80::/64 dev enp0s8 proto kernel metric 256 pref medium
```

- `::1 dev lo proto kernel metric 256 pref medium`: The destination network is "::1", which is the loopback address. The interface through which the network can be reached is "lo" (the loopback interface). The routing protocol used is "kernel", meaning that it is managed by the kernel. The metric is "256", which is a value used to determine the preferred path to the destination network. The preference is "medium", which is a value used to determine the order in which routes are selected when multiple routes to the same destination exist.
- `fd01:2345:6789:abc1::/64 dev enp0s8 proto kernel metric 256 pref medium`: The destination network is "fd01:2345:6789:abc1::/64". The interface through which the network can be reached is "enp0s8". The routing protocol used is "kernel", meaning that it is managed by the kernel. The metric is "256", which is a value used to determine the preferred path to the destination network. The preference is "medium", which is a value used to determine the order in which routes are selected when multiple routes to the same destination exist.
- `fd01:2345:6789:abc2::/64 via fd01:2345:6789:abc1::1 dev enp0s8 metric 1024 pref medium`: This line describes a route in the IPv6 routing table. The destination network is "fd01:2345:6789:abc2::/64". The next hop (the intermediate device through which the network can be reached) is "fd01:2345:6789:abc1::1". The interface through which the next hop can be reached is "enp0s8". The routing protocol used is "kernel", meaning that it is managed by the kernel. The metric is "1024", which is a value used to determine the preferred path to the destination network. The preference is "medium", which is a value used to determine the order in which routes are selected when multiple routes to the same destination exist.

A double colon (::) in an IPv6 address indicates that **one or more groups of 16-bits zeros are omitted** and replaced with a double colon. It represents consecutive groups of zeros and is used as a shorthand for writing IPv6 addresses.



### 2.6 Start *tcpdump* to capture ICMPv6 packets on each machine. From lab2, ping the lab1 and lab3 IPv6 addresses using ping6(8). You should get a return packet for each ping you have sent. If not, recheck your network configuration. Show the headers of a successful ping return packet. Show *ping6* output as well as *tcpdump* output.

ping6 on lab2:
```bash
vagrant@lab2:~$ ping6 fd01:2345:6789:abc1::1
PING fd01:2345:6789:abc1::1(fd01:2345:6789:abc1::1) 56 data bytes
64 bytes from fd01:2345:6789:abc1::1: icmp_seq=1 ttl=64 time=0.221 ms
64 bytes from fd01:2345:6789:abc1::1: icmp_seq=2 ttl=64 time=0.227 ms
^C
--- fd01:2345:6789:abc1::1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1008ms
rtt min/avg/max/mdev = 0.221/0.224/0.227/0.003 ms
vagrant@lab2:~$ ping6 fd01:2345:6789:abc2::1
PING fd01:2345:6789:abc2::1(fd01:2345:6789:abc2::1) 56 data bytes
64 bytes from fd01:2345:6789:abc2::1: icmp_seq=1 ttl=64 time=0.334 ms
64 bytes from fd01:2345:6789:abc2::1: icmp_seq=2 ttl=64 time=0.264 ms
^C
--- fd01:2345:6789:abc2::1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1005ms
rtt min/avg/max/mdev = 0.264/0.299/0.334/0.035 ms
vagrant@lab2:~$ ping6 fd01:2345:6789:abc2::2
PING fd01:2345:6789:abc2::2(fd01:2345:6789:abc2::2) 56 data bytes
64 bytes from fd01:2345:6789:abc2::2: icmp_seq=1 ttl=63 time=0.479 ms
64 bytes from fd01:2345:6789:abc2::2: icmp_seq=2 ttl=63 time=0.399 ms
^C
--- fd01:2345:6789:abc2::2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1020ms
rtt min/avg/max/mdev = 0.399/0.439/0.479/0.040 ms
```

tcpdump on lab1:

```
vagrant@lab1:~$ sudo tcpdump -i enp0s8 -i enp0s9
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:33:33.635831 IP6 fd01:2345:6789:abc1::2 > fd01:2345:6789:abc2::2: ICMP6, echo request, id 20, seq 1, length 64
15:33:33.636053 IP6 fd01:2345:6789:abc2::2 > fd01:2345:6789:abc1::2: ICMP6, echo reply, id 20, seq 1, length 64
15:33:34.655320 IP6 fd01:2345:6789:abc1::2 > fd01:2345:6789:abc2::2: ICMP6, echo request, id 20, seq 2, length 64
15:33:34.655511 IP6 fd01:2345:6789:abc2::2 > fd01:2345:6789:abc1::2: ICMP6, echo reply, id 20, seq 2, length 64
15:33:38.748931 IP6 fe80::a00:27ff:fed0:3ce2 > lab1: ICMP6, neighbor solicitation, who has lab1, length 32
15:33:38.748955 IP6 lab1 > fe80::a00:27ff:fed0:3ce2: ICMP6, neighbor advertisement, tgt is lab1, length 24
15:33:38.782983 IP6 lab1 > fd01:2345:6789:abc2::2: ICMP6, neighbor solicitation, who has fd01:2345:6789:abc2::2, length 32
15:33:38.783200 IP6 fd01:2345:6789:abc2::2 > lab1: ICMP6, neighbor advertisement, tgt is fd01:2345:6789:abc2::2, length 24
15:33:43.869028 IP6 fe80::a00:27ff:fed0:3ce2 > lab1: ICMP6, neighbor solicitation, who has lab1, length 32
15:33:43.869052 IP6 lab1 > fe80::a00:27ff:fed0:3ce2: ICMP6, neighbor advertisement, tgt is lab1, length 24
15:33:43.899135 IP6 lab1 > fe80::a00:27ff:fed0:3ce2: ICMP6, neighbor solicitation, who has fe80::a00:27ff:fed0:3ce2, length 32
15:33:43.899369 IP6 fe80::a00:27ff:fed0:3ce2 > lab1: ICMP6, neighbor advertisement, tgt is fe80::a00:27ff:fed0:3ce2, length 24
```

tcpdump on lab2:

```bash
vagrant@lab2:~$ sudo tcpdump -i enp0s8
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:15:21.614051 IP6 lab2 > fd01:2345:6789:abc1::1: ICMP6, echo request, id 18, seq 1, length 64
15:15:21.614253 IP6 fd01:2345:6789:abc1::1 > lab2: ICMP6, echo reply, id 18, seq 1, length 64
15:15:22.622191 IP6 lab2 > fd01:2345:6789:abc1::1: ICMP6, echo request, id 18, seq 2, length 64
15:15:22.622392 IP6 fd01:2345:6789:abc1::1 > lab2: ICMP6, echo reply, id 18, seq 2, length 64
15:15:54.258038 IP6 lab2 > fd01:2345:6789:abc2::1: ICMP6, echo request, id 19, seq 1, length 64
15:15:54.258355 IP6 fd01:2345:6789:abc2::1 > lab2: ICMP6, echo reply, id 19, seq 1, length 64
15:15:55.262995 IP6 lab2 > fd01:2345:6789:abc2::1: ICMP6, echo request, id 19, seq 2, length 64
15:15:55.263228 IP6 fd01:2345:6789:abc2::1 > lab2: ICMP6, echo reply, id 19, seq 2, length 64
15:15:59.292347 IP6 fe80::a00:27ff:feef:9233 > lab2: ICMP6, neighbor solicitation, who has lab2, length 32
15:15:59.292377 IP6 lab2 > fe80::a00:27ff:feef:9233: ICMP6, neighbor advertisement, tgt is lab2, length 24
15:15:59.422151 IP6 lab2 > fd01:2345:6789:abc1::1: ICMP6, neighbor solicitation, who has fd01:2345:6789:abc1::1, length 32
15:15:59.422365 IP6 fd01:2345:6789:abc1::1 > lab2: ICMP6, neighbor advertisement, tgt is fd01:2345:6789:abc1::1, length 24
15:16:04.542940 IP6 lab2 > fe80::a00:27ff:feef:9233: ICMP6, neighbor solicitation, who has fe80::a00:27ff:feef:9233, length 32
15:16:04.543157 IP6 fe80::a00:27ff:feef:9233 > lab2: ICMP6, neighbor advertisement, tgt is fe80::a00:27ff:feef:9233, length 24
15:16:04.667990 IP6 fe80::a00:27ff:feef:9233 > lab2: ICMP6, neighbor solicitation, who has lab2, length 32
15:16:04.668013 IP6 lab2 > fe80::a00:27ff:feef:9233: ICMP6, neighbor advertisement, tgt is lab2, length 24
15:16:38.947930 IP6 lab2 > fd01:2345:6789:abc2::2: ICMP6, echo request, id 20, seq 1, length 64
15:16:38.948397 IP6 fd01:2345:6789:abc2::2 > lab2: ICMP6, echo reply, id 20, seq 1, length 64
15:16:39.967452 IP6 lab2 > fd01:2345:6789:abc2::2: ICMP6, echo request, id 20, seq 2, length 64
15:16:39.967826 IP6 fd01:2345:6789:abc2::2 > lab2: ICMP6, echo reply, id 20, seq 2, length 64
15:16:44.095272 IP6 fe80::a00:27ff:feef:9233 > lab2: ICMP6, neighbor solicitation, who has lab2, length 32
15:16:44.095292 IP6 lab2 > fe80::a00:27ff:feef:9233: ICMP6, neighbor advertisement, tgt is lab2, length 24
```

tcpdump on lab3:
```
vagrant@lab3:~$ sudo tcpdump -i enp0s8
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:33:33.630970 IP6 fd01:2345:6789:abc1::2 > lab3: ICMP6, echo request, id 20, seq 1, length 64
15:33:33.630995 IP6 lab3 > fd01:2345:6789:abc1::2: ICMP6, echo reply, id 20, seq 1, length 64
15:33:34.650421 IP6 fd01:2345:6789:abc1::2 > lab3: ICMP6, echo request, id 20, seq 2, length 64
15:33:34.650445 IP6 lab3 > fd01:2345:6789:abc1::2: ICMP6, echo reply, id 20, seq 2, length 64
15:33:38.743803 IP6 lab3 > fd01:2345:6789:abc2::1: ICMP6, neighbor solicitation, who has fd01:2345:6789:abc2::1, length 32
15:33:38.744011 IP6 fd01:2345:6789:abc2::1 > lab3: ICMP6, neighbor advertisement, tgt is fd01:2345:6789:abc2::1, length 24
15:33:38.778039 IP6 fe80::a00:27ff:fed0:87e0 > lab3: ICMP6, neighbor solicitation, who has lab3, length 32
15:33:38.778064 IP6 lab3 > fe80::a00:27ff:fed0:87e0: ICMP6, neighbor advertisement, tgt is lab3, length 24
15:33:43.863835 IP6 lab3 > fe80::a00:27ff:fed0:87e0: ICMP6, neighbor solicitation, who has fe80::a00:27ff:fed0:87e0, length 32
15:33:43.864070 IP6 fe80::a00:27ff:fed0:87e0 > lab3: ICMP6, neighbor advertisement, tgt is fe80::a00:27ff:fed0:87e0, length 24
15:33:43.894181 IP6 fe80::a00:27ff:fed0:87e0 > lab3: ICMP6, neighbor solicitation, who has lab3, length 32
15:33:43.894207 IP6 lab3 > fe80::a00:27ff:fed0:87e0: ICMP6, neighbor advertisement, tgt is lab3, length 24
```

- Version: This field indicates the version of the IP protocol being used. For IPv6, this value is always set to 6.
- Traffic Class: This field is used to prioritize traffic and control congestion. It consists of two subfields: the 6-bit Differentiated Services Code Point (DSCP) and the 2-bit Explicit Congestion Notification (ECN) field.
- Flow Label: This field is used to identify packets that belong to the same flow or session. It is a 20-bit field that is set by the sender and should be kept unchanged by intermediate routers.
- Payload Length: This field indicates the length of the payload (i.e., the data being transmitted) in bytes.
- Next Header: This field indicates the protocol of the next header in the packet after the IPv6 header. For a successful ping return packet, this value would typically be set to ICMPv6 (Internet Control Message Protocol version 6).
- Hop Limit: This field limits the number of routers that a packet can traverse before being discarded. It is decremented by each router that forwards the packet, and the packet is discarded when the hop limit reaches zero.
- Source Address: This field indicates the IPv6 address of the sender.
- Destination Address: This field indicates the IPv6 address of the intended recipient (i.e., the address that was pinged).



## 3 IPv6 Router Advertisement Daemon

Instead of having to manually assign the addresses to the interfaces, this can be done by the router, so they automatically get an address assigned to them.

Set up Router Advertisement Daemon on lab1 to automatically assign IPv6 addresses to VMs connected to intnet1 and intnet2.

1. On **lab2 and lab3:** Remove all static addresses from the intnet interfaces and run the interfaces down.
   ```bash
   sudo ip -6 addr flush dev enp0s8
   sudo ip link set down dev enp0s8
   ```

2. **lab1:** Install IPv6 Router Advertisement Daemon (radvd). Modify the content of *radvd.conf* file to be used in your network (If *radvd.conf* file does not exist create one under */etc* directory). Radvd should advertise prefix **fd01:2345:6789:abc1::/64** on intnet1 (enp0s8) and **fd01:2345:6789:abc2::/64** on intnet2 (enp0s9). Start the router advertisement daemon (radvd).

   ```bash
   sudo apt install radvd
   ```

   create a file /etc/radvd.conf:
   ```
   interface enp0s8
   {
     AdvSendAdvert on;
     AdvManagedFlag on;
     AdvOtherConfigFlag on;
     prefix fd01:2345:6789:abc1::/64
     {
       AdvOnLink on;
       AdvAutonomous on;
     };
   };
   
   interface enp0s9
   {
     AdvSendAdvert on;
     AdvManagedFlag on;
     AdvOtherConfigFlag on;
     prefix fd01:2345:6789:abc2::/64
     {
       AdvOnLink on;
       AdvAutonomous on;
     };
   };
   ```

   start the radvd service

   ```bash
   sudo systemctl start radvd
   ```

3. Check using *tcpdump* that router advertisement packets are sent to enp0s8 and enp0s9 of lab1 periodically. If you can’t see any packets sent, edit the conf file.
   ```bash
   sudo tcpdump -i enp0s8 -i enp0s9 icmp6
   ```

4. Start *tcpdump* on **lab2** and capture ICMPv6 packets. Bring the interfaces on **lab2** and **lab3** up. Stop capturing packets after receiving first few ICMPv6 packets. Make sure the addresses that are assigned to the interfaces are received from the router advertisement.
   ```bash
   sudo tcpdump -i enp0s8 icmp6
   sudo ip link set up dev enp0s8
   ```

5. Ping **lab3** from **lab2** using the IPv6 address allocated by radvd. You should get a return packet for each ping you have sent. If not, recheck your network configuration.
   ```bash
   vagrant@lab2:~$ ping6 fd01:2345:6789:abc2:a00:27ff:fed0:3ce2
   PING fd01:2345:6789:abc2:a00:27ff:fed0:3ce2(fd01:2345:6789:abc2:a00:27ff:fed0:3ce2) 56 data bytes
   64 bytes from fd01:2345:6789:abc2:a00:27ff:fed0:3ce2: icmp_seq=1 ttl=63 time=0.654 ms
   64 bytes from fd01:2345:6789:abc2:a00:27ff:fed0:3ce2: icmp_seq=2 ttl=63 time=0.427 ms
   64 bytes from fd01:2345:6789:abc2:a00:27ff:fed0:3ce2: icmp_seq=3 ttl=63 time=0.420 ms
   64 bytes from fd01:2345:6789:abc2:a00:27ff:fed0:3ce2: icmp_seq=4 ttl=63 time=0.432 ms
   64 bytes from fd01:2345:6789:abc2:a00:27ff:fed0:3ce2: icmp_seq=5 ttl=63 time=0.383 ms
   ^C
   --- fd01:2345:6789:abc2:a00:27ff:fed0:3ce2 ping statistics ---
   5 packets transmitted, 5 received, 0% packet loss, time 4102ms
   rtt min/avg/max/mdev = 0.383/0.463/0.654/0.096 ms
   ```

   



### 3.1 Explain your modifications to *radvd.conf*. Which options are mandatory?

- `AdvManagedFlag on;`: Managed Address Configuration flag in Router Advertisements (RAs) is set to "on". The Managed Address Configuration flag indicates whether stateful address autoconfiguration, such as DHCPv6, is available on the network.
- `AdvOtherConfigFlag on;`: Other Configuration flag in Router Advertisements (RAs) is set to "on". The Other Configuration flag indicates whether stateless address autoconfiguration, such as SLAAC, is available on the network.
- `AdvOnLink on;`: The prefix is directly on-link, meaning the prefix is directly reachable within the local network segment.
- `AdvAutonomous on;` :The prefix can be used for autoconfiguration of addresses, meaning that hosts can generate their own IPv6 addresses based on this prefix without the need for manual configuration or a DHCP server.

Mandatory options:

- `interface` specifies the interface name to which the prefix will be advertised.
- `AdvSendAdvert on;` enables the advertisement of prefixes on the interface.
- `prefix` specifies the prefix to be advertised.

### 



### 3.2 Analyze captured packets and explain what happens when you set up the interface on lab2.

```
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:34:40.177040 IP6 _gateway > ip6-allnodes: ICMP6, router advertisement, length 56
16:34:56.193194 IP6 _gateway > ip6-allnodes: ICMP6, router advertisement, length 56
```

When the interface on lab2 is set up, it listens for Router Advertisement packets. The router advertisement packets contain information about the prefixes available on the network, as well as other information such as the default gateway and the preferred and valid lifetimes of the prefixes. Upon receipt of the router advertisement packet, lab2 uses the information to autoconfigure its address.



### 3.3 How is the host-specific part of the address determined in this case?

The host-specific part of the address is determined by the host generating a random interface identifier (IID) and concatenating it with the prefix obtained from the router advertisement. The IID is usually generated from the MAC address of the interface.





### 3.4 Show and explain the output of a *traceroute(1)* from lab2 to lab3.

Command:

```bash
traceroute -6 fd01:2345:6789:abc2:a00:27ff:fed0:3ce2
```

Result:

```
traceroute to fd01:2345:6789:abc2:a00:27ff:fed0:3ce2 (fd01:2345:6789:abc2:a00:27ff:fed0:3ce2), 30 hops max, 80 byte packets
 1  fd01:2345:6789:abc1:a00:27ff:feef:9233 (fd01:2345:6789:abc1:a00:27ff:feef:9233)  0.348 ms  0.303 ms  0.374 ms
 2  fd01:2345:6789:abc2:a00:27ff:fed0:3ce2 (fd01:2345:6789:abc2:a00:27ff:fed0:3ce2)  0.782 ms  0.771 ms  0.867 ms
```

The route of packet: lab2 enp0s8 -> lab1 enp0s8 -> lab3 enp0s8

It shows the hops(which is the router) on the route from lab2 to lab3



## 4 Cofigure IPv6 over IPv4

Ideally, IPv6 should be run natively wherever possible, with IPv6 devices communicating with each other directly over IPv6 networks. However, the move from IPv4 to IPv6 will happen over time. The Internet Engineering Task Force (IETF) has developed several transition techniques to accommodate a variety of IPv4-to-IPv6 scenarios. One type of IPv4–to–IPv6 transition mechanism is translation including NAT64, Mapping of Address and Port (MAP), IPv6 Rapid Deployment (6rd), etc.

In this part of the assignment the goal is to demonstrate two ipv6 only nodes communicating with each other and the global internet through an ipv4 link. You will need to spin up another VM, lab4 for this part of the assignment to setup the network shown below, which has two IPv6 only nodes and two nodes with both IPv6 and IPv4 capabilities but only an IPv4 link connecting them to each other

1. Reset the networking on lab1, lab2 and lab3 back to default.
2. Create a new VM named lab4. Lab4 should have a NAT adapter for you to be able to ssh into and administer it, so set up port forwarding accordingly
3. On lab3 and lab4, add a network adapter of type internal network and name it intnet3
4. On lab2 and lab4, disable all static IPv4 addresses on the intent adapters. Create an IPv6 link between lab2 and lab1 assigning static addresses from the fd01:2345:6789:abc1::/64 subnet, similarly create an IPv6 link between lab3 and lab4 assigning addresses from the subnet fd01:2345:6789:abc2::/64.
5. Between lab1 and lab3 setup an IPv4 link with static addresses from 192.168.0.0/16
6. Make sure only lab3 has internet access. Configure your routing so that lab3 is used as the internet gateway



### 4.1 Do a traceroute from lab2 to lab4, showing it taking the route through lab1 and lab3



### 4.2 Show that you can ping 8.8.8.8 from lab1 and lab4

```
ping 8.8.8.8
```



### 4.3 Explain your solution. Why did you use this method over the other options?

To realize the IPv6 over IPv4 connection, a 6rd tunnel is built. 

To realize the IPv4 in IPv6, ip4ip6 tunnel is built.

I used 6rd because it is easier to deployed and there are exsiting documentation & tutorials. Also, it can be compatible with the existing IPv4 infrastructure.



### 4.4 Are there security issues with your solution? What and how can they be addressed?

Problems: Leaking addresses, addresses spoofing (combination of IPv6 and IPv4)

Address: Properly manage the IPv6 address space, more complex address generation algorithms