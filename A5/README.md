# A5: Firewall



## 0  Introduction

> Additional Reading:
>
> - [route manual page](https://man7.org/linux/man-pages/man8/route.8.html#top_of_page)
> - [Nftables documentation](https://netfilter.org/projects/nftables/)
> - [Squid documentation](https://web.archive.org/web/20161123064052/http:/www.deckle.co.uk/squid-users-guide/)



### 0.1 Motivation

A firewall is a network security system used for monitoring and controlling network traffic. Setting up a firewall gives you control over which packets you want to let through and where to direct them. Furthermore, you can log the traffic going through the firewall to identify unusual behavior. A router hosting Network Address Translation (NAT) can act as a firewall, directing communications from a certain port to a certain IP address. Many consumer routers have firewall capabilities in them, allowing similar control to the ones set up in this assignment.



### 0.2 Description

A firewall is a network security system used for monitoring and controlling network traffic. Setting up a firewall gives you control over which packets you want to let through and where to direct them. Furthermore, you can log the traffic going through the firewall to identify unusual behavior. A router hosting Network Address Translation (NAT) can act as a firewall, directing communications from a certain port to a certain IP address. Many consumer routers have firewall capabilities in them, allowing similar control to the ones set up in this assignment.



## 1 Preparation

*If you are doing both paths, you might want to consider making new virtual machines for this exercise*, because the two assignments might cause some conflicts or problems.

You will need all three virtual machines for this exercise. Lab1 functions as a router/firewall between lab2 and lab3, which are in different subnetworks. The enp0s3 interface allows access to the virtual machines. Be careful not to modify it or block access to it. Make sure you are not sending packets through enp0s3 when connecting to other virtual machines, because that way you will bypass the firewall. The communication between VMs should be through the internal networks.

Please remember to take backups of the folders you have modified on the virtual machines.



## 2 Set up the network

You will configure lab1 to act as a router between lab2 and lab3. 

On lab1:

- Assign a static IP from the subnet 192.168.0.0/24 to the interface enp0s8
- Assign a static IP from the subnet 192.168.2.0/24 to the interface enp0s9

On lab2:

- Assign a static IP from the subnet 192.168.0.0/24 to the interface enp0s8

On lab3:

- Assign a static IP from the subnet 192.168.2.0/24 to the interface enp0s8

On lab1:

- Add lab2 and lab3 static IP's to /etc/hosts, remove all other lab2 and lab3 mentions

On lab2:

- Add lab1 static IP (that is in the same network as lab2) to /etc/hosts, remove all other lab1 mentions
- Add lab3 static IP to /etc/hosts, remove all other mentions

On lab3:

- Add lab1 static IP (that is in the same network as lab3) to /etc/hosts, remove all other lab1 mentions
- Add lab2 static IP to /etc/hosts, remove all other mentions

On lab1:

- Add routes to both subnets (192.168.0.0/24 and 192.168.2.0/24) via the interfaces connected to those

On lab2 & lab3:

- Add the necessary route to allow the machines to reach each other through **lab1**.

Do not change the default gateway or you will lose your connection to the machines.

Enable forwarding and arp proxying on **lab1** for the enp0s8 and enp0s9 interfaces. Use the following *sysctl(8)* commands:

sysctl -w net.ipv4.conf.enp0s8.forwarding=1
sysctl -w net.ipv4.conf.enp0s9.forwarding=1
sysctl -w net.ipv4.conf.enp0s8.proxy_arp=1
sysctl -w net.ipv4.conf.enp0s9.proxy_arp=1

Check that there is no firewall rules at this point (*iptables -L*), and test that routing works by using *traceroute(8)* from **lab2** to **lab3**. Make sure that the route uses lab1 and the correct static IPs.



### 2.1 List all commands you used to create the router setup, and briefly explain what they do. Show the results of the traceroute as well.

```bash
# lab1
sudo ip route add 192.168.0.0/24 dev enp0s8
                            
sudo ip route add 192.168.2.0/24 dev enp0s9

# enables IP forwarding
sysctl -w net.ipv4.conf.enp0s8.forwarding=1
sysctl -w net.ipv4.conf.enp0s9.forwarding=1

# enables proxy ARP on the "enp0s8" network interface
# Proxy ARP allows a system to respond to ARP requests on behalf of another system. 
sysctl -w net.ipv4.conf.enp0s8.proxy_arp=1
sysctl -w net.ipv4.conf.enp0s9.proxy_arp=1

# lab2
sudo ip route add 192.168.2.0/24 via 192.168.0.2 dev enp0s8


# lab3
sudo ip route add 192.168.0.0/24 via 192.168.2.2 dev enp0s8
```

```bash
vagrant@lab3:~$ traceroute lab2
traceroute to lab2 (192.168.0.3), 64 hops max
  1   192.168.2.2  1.270ms  0.381ms  0.264ms
  2   192.168.0.3  1.282ms  0.512ms  0.462ms

vagrant@lab2:~$ traceroute lab3
traceroute to lab3 (192.168.2.3), 64 hops max
  1   192.168.0.2  0.694ms  0.430ms  0.420ms
  2   192.168.2.3  0.739ms  0.449ms  0.446ms
```





### 2.2 Explain tables, chains, hooks and rules in nftables?

Tables: Tables are the top-level containers that group chains and define the type of packet filtering or manipulation to be performed. Each table has a unique name and is identified by a family, which can be one of the following: ip, ip6, inet, or arp. Tables can be created, deleted, and modified using the nft command-line tool or via a configuration file.

Chains: Chains are the second level of the nftables structure and are used to define a set of rules for packet filtering or manipulation. Chains can be attached to different hooks, which define the point in the packet processing path where the chain should be executed. The most common hooks are pre-routing, input, forward, output, and post-routing.

Hooks: Hooks define the point in the packet processing path where a chain should be executed. There are five main hooks in nftables:

- PREROUTING: This hook is executed before a packet is routed and can be used to modify the packet's source address, destination address, or transport protocol.
- INPUT: This hook is executed when a packet is destined for the local machine.
- FORWARD: This hook is executed when a packet is forwarded to another machine.
- OUTPUT: This hook is executed when a packet is generated by the local machine and is destined for another machine.
- POSTROUTING: This hook is executed after a packet has been routed and can be used to modify the packet's source address, destination address, or transport protocol.

Rules: Rules are the third level of the nftables structure and define the specific actions to be taken for a packet that matches a particular set of criteria. Each rule consists of a set of expressions that match against a packet's metadata, such as its source and destination addresses, transport protocol, and port numbers. If a packet matches a rule, the associated action is taken, which can be one of the following: accept, drop, reject, or jump to another chain.

In summary, `nftables` uses tables to organize chains, which contain rules that are applied to packets at specific points in the networking stack (hooks). This modular and hierarchical structure allows for flexible and efficient packet filtering and manipulation in Linux systems.



## 3 Implement packet filtering on the router

First, scan **lab3** from **lab2** and vice versa with *nmap(1)* to see what services they are running. Try to gather as much information on the machine as feasible, including information about software versions and the operating system. To make the results more diverse, install an FTP server (e.g. *proftpd(8)*) and a web server (e.g. apache) on lab3.

Set up an *nftables(8)* FORWARD policy to disallow traffic through the router by default. Add rules to allow *ping(8)* from **lab2** on the enp0s8 interface and replies to **lab2**. Change rules only for the FORWARD hook! Once this is working, expand the ruleset to allow SSH connections to and from **lab2**. Also allow browsing the web and transferring files via FTP (both active and passive modes) from **lab2**. Use as restricting ruleset as possible while allowing full functionality. You will probably need the "ip_conntrack_ftp" kernel module for FTP filtering. Load it with *modprobe(8)*.

Finally, rescan **lab3** from **lab2** and vice versa.



### 3.1  List the services that were found scanning the machines with and without the firewall active. Explain the differences in how the details of the system were detected.

Before

```bash
vagrant@lab2:~$ sudo nmap -sV -p- lab3
Starting Nmap 7.80 ( https://nmap.org ) at 2024-03-21 17:04 UTC
Nmap scan report for lab3 (192.168.2.3)
Host is up (0.00023s latency).
Not shown: 65532 closed ports
PORT   STATE SERVICE VERSION
21/tcp open  ftp     ProFTPD
22/tcp open  ssh     OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.52 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 15.58 seconds


vagrant@lab3:~$ sudo nmap -sV -p- lab2
Starting Nmap 7.80 ( https://nmap.org ) at 2024-03-21 17:00 UTC
Nmap scan report for lab2 (192.168.0.3)
Host is up (0.00025s latency).
Not shown: 65534 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 3.55 second
```

After
```
vagrant@lab2:~$ sudo nmap -sV -p- lab3
Starting Nmap 7.80 ( https://nmap.org ) at 2024-03-21 18:10 UTC
Nmap scan report for lab3 (192.168.2.3)
Host is up (0.00059s latency).
Not shown: 65532 closed ports
PORT   STATE SERVICE VERSION
21/tcp open  ftp     ProFTPD
22/tcp open  ssh     OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.52 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 14.10 seconds



vagrant@lab3:~$ sudo nmap -sV -p- -Pn lab2
Starting Nmap 7.80 ( https://nmap.org ) at 2024-03-21 18:08 UTC
Nmap scan report for lab2 (192.168.0.3)
Host is up (0.0019s latency).
All 65535 scanned ports on lab2 (192.168.0.3) are filtered (49151) or closed (16384)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 60.90 seconds
```

This is because the firewall may be blocking ports and services. Nmap detects system details by sending a series of TCP and UDP packets to the remote host and examining practically every bit in the responses. Nmap then runs various tests from TCP ISN sampling to IP ID sampling and compares it to its internal database of 2,600 operating systems





### 3.2 List the commands used to implement the ruleset with explanations.

```bash
sudo nft add table inet filter

udo nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }

sudo nft add rule inet filter forward iif enp0s8 icmp type echo-request counter accept

sudo nft add rule inet filter forward oif enp0s8 icmp type echo-reply counter accept

sudo nft add rule inet filter forward iif enp0s8 tcp dport 22 ct state new,established counter accept

sudo nft add rule inet filter forward oif enp0s8 tcp sport 22 ct state established counter accept


sudo nft add rule inet filter forward iif enp0s8 tcp dport 80 ct state new,established counter accept

sudo nft add rule inet filter forward oif enp0s8 tcp sport 80 ct state established counter accept

sudo nft add rule inet filter forward iif enp0s8 tcp dport {20-21} counter accept

sudo nft add rule inet filter forward oif enp0s8 tcp sport {20-21} counter accept

sudo nft add rule inet filter forward iif enp0s9 tcp dport {49152-65535} counter accept

sudo nft add rule inet filter forward oif enp0s9 tcp sport {49152-65535} counter accept

sudo modprobe ip_conntrack_ftp
```







### 3.3 Create a few test cases to verify your ruleset. Run the tests and provide minimal, but sufficient snippets of logs to support your test results, including dropping unallowed cases.

```bash
vagrant@lab2:~$ ftp lab3
Connected to lab3.
220 ProFTPD Server (Debian) [::ffff:192.168.2.3]
Name (lab3:vagrant): vagrant
331 Password required for vagrant
Password:
230 User vagrant logged in
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> put test.txt
local: test.txt remote: test.txt
229 Entering Extended Passive Mode (|||64380|)
150 Opening BINARY mode data connection for test.txt
     0        0.00 KiB/s
226 Transfer complete
ftp> quit


vagrant@lab2:~$ curl -I lab3
HTTP/1.1 200 OK
Date: Thu, 21 Mar 2024 23:01:16 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Thu, 21 Mar 2024 23:53:08 GMT
ETag: "29af-614334dbd4043"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
```

```bash
sudo tcpdump -I enp0s8
```

```

23:02:51.812494 IP lab3.ftp > lab2.46990: Flags [P.], seq 723:771, ack 87, win 510, options [nop,nop,TS val 85084485 ecr 246913186], length 48: FTP: 229 Entering Extended Passive Mode (|||26889|)
23:02:51.813487 IP lab2.46990 > lab3.ftp: Flags [.], ack 771, win 16652, options [nop,nop,TS val 246913188 ecr 85084485], length 0
23:02:51.813658 IP lab2.54376 > lab3.26889: Flags [S], seq 540756081, win 65535, options [mss 1460,sackOK,TS val 246913189 ecr 0,nop,wscale 2], length 0
23:02:51.813692 IP lab3.26889 > lab2.54376: Flags [S.], seq 3813125044, ack 540756082, win 65160, options [mss 1460,sackOK,TS val 85084487 ecr 246913189,nop,wscale 7], length 0
23:02:51.814521 IP lab2.54376 > lab3.26889: Flags [.], ack 1, win 16384, options [nop,nop,TS val 246913189 ecr 85084487], length 0
23:02:51.814785 IP lab2.46990 > lab3.ftp: Flags [P.], seq 87:102, ack 771, win 16652, options [nop,nop,TS val 246913190 ecr 85084485], length 15: FTP: STOR test.txt
23:02:51.815361 IP lab3.ftp > lab2.46990: Flags [P.], seq 771:825, ack 102, win 510, options [nop,nop,TS val 85084488 ecr 246913190], length 54: FTP: 150 Opening BINARY mode data connection for test.txt
23:02:51.816658 IP lab2.54376 > lab3.26889: Flags [F.], seq 1, ack 1, win 16384, options [nop,nop,TS val 246913191 ecr 85084487], length 0
23:02:51.816808 IP lab3.26889 > lab2.54376: Flags [F.], seq 1, ack 2, win 510, options [nop,nop,TS val 85084490 ecr 246913191], length 0
23:02:51.817121 IP lab3.ftp > lab2.46990: Flags [P.], seq 825:848, ack 102, win 510, options [nop,nop,TS val 85084490 ecr 246913190], length 23: FTP: 226 Transfer complete
23:02:51.817730 IP lab2.54376 > lab3.26889: Flags [.], ack 2, win 16384, options [nop,nop,TS val 246913193 ecr 85084490], length 0
23:02:51.817970 IP lab2.46990 > lab3.ftp: Flags [.], ack 848, win 16652, options [nop,nop,TS val 246913193 ecr 85084488], length 0


23:03:16.099103 IP lab2.51932 > lab3.http: Flags [S], seq 2654095637, win 64240, options [mss 1460,sackOK,TS val 246937474 ecr 0,nop,wscale 7], length 0
23:03:16.099141 IP lab3.http > lab2.51932: Flags [S.], seq 1345055939, ack 2654095638, win 65160, options [mss 1460,sackOK,TS val 85108772 ecr 246937474,nop,wscale 7], length 0
23:03:16.100122 IP lab2.51932 > lab3.http: Flags [.], ack 1, win 502, options [nop,nop,TS val 246937475 ecr 85108772], length 0
23:03:16.100122 IP lab2.51932 > lab3.http: Flags [P.], seq 1:70, ack 1, win 502, options [nop,nop,TS val 246937475 ecr 85108772], length 69: HTTP: HEAD / HTTP/1.1
23:03:16.100167 IP lab3.http > lab2.51932: Flags [.], ack 70, win 509, options [nop,nop,TS val 85108773 ecr 246937475], length 0
23:03:16.100585 IP lab3.http > lab2.51932: Flags [P.], seq 1:256, ack 70, win 509, options [nop,nop,TS val 85108774 ecr 246937475], length 255: HTTP: HTTP/1.1 200 OK
23:03:16.101599 IP lab2.51932 > lab3.http: Flags [.], ack 256, win 501, options [nop,nop,TS val 246937477 ecr 85108774], length 0
23:03:16.101599 IP lab2.51932 > lab3.http: Flags [F.], seq 70, ack 256, win 501, options [nop,nop,TS val 246937477 ecr 85108774], length 0
23:03:16.101821 IP lab3.http > lab2.51932: Flags [F.], seq 256, ack 71, win 509, options [nop,nop,TS val 85108775 ecr 246937477], length 0
23:03:16.102679 IP lab2.51932 > lab3.http: Flags [.], ack 257, win 501, options [nop,nop,TS val 246937478 ecr 85108775], length 0
```







### 3.4 Explain the difference between netfilter DROP and REJECT targets. Test both of them, and explain your findings.

DROP and REJECT are both used to block incoming traffic, but they have different behaviors. The main difference between DROP and REJECT is how they respond to blocked traffic.

DROP simply discards incoming traffic without sending any response back to the source. When a packet is dropped, the sender doesn't know that the packet was blocked, and may continue to send additional packets. This can be useful in some cases where you want to silently drop traffic without alerting the sender.

REJECT, on the other hand, sends an error message back to the source to indicate that the traffic was blocked. This lets the sender know that their traffic is being blocked, and they can take appropriate action. This can be useful when you want to block traffic but also want to notify the sender of the reason for the block.



On lab1:

```bash
sudo nft add rule inet filter forward iif enp0s8 tcp dport 1234 counter reject

# sudo nft -a list table inet filter
# sudo nft delete rule inet filter forward handle 16
```

Test on lab2:

```bash
vagrant@lab2:~$ telnet lab3 1234
Trying 192.168.2.3...
telnet: Unable to connect to remote host: Connection refused

vagrant@lab2:~$ telnet lab3 1235
Trying 192.168.2.3...
```





## 4 Implement a web proxy

In addition to packet filtering, a proxy can be used to control traffic. In this step, you will set up a web proxy and force all http traffic to go through the proxy, where more detailed rules can be applied.

- Connect from **lab2** to the HTTP server running on **lab3** and capture the headers of the response.
- On **lab1**, configure a *squid(8)* web proxy to serve only requests from **lab2** as a transparent proxy.
- Configure the firewall on **lab1** to send all TCP traffic from **lab2** bound to port 80 to the squid proxy.
- Connect to the HTTP server on **lab3** again and capture the headers of the response.
- Finally, configure the proxy not to serve pages from **lab3** and attempt to retrieve the front page.



### 4.1 List the commands you used to send the traffic to the proxy with explanations.

```bash
sudo nft add table ip filter

sudo nft add chain ip filter prerouting { type nat hook prerouting priority 0 \; policy accept \; }

sudo nft add rule ip filter prerouting iifname enp0s8 ip saddr lab2 tcp dport 80 redirect to :8000
```





### 4.2 Show and explain the changes you made to the squid.conf.

```
# This line tells squid to listen on port 8000 and act as a transparent proxy.
http_port 8000 transparent

 # This line defines an access control list (acl) named lab2 that matches the source IP address of lab2.
acl lab2 src 192.168.0.3

# This line allows HTTP access for the acl lab2.
http_access allow lab2

# acl lab3 dst 192.168.2.2

# never_direct allow lab3
```





### 4.3 What is a transparent proxy?

A transparent proxy is a proxy that intercepts and modifies all traffic that is sent to a certain destination without requiring any configuration or awareness from the client. A transparent proxy can be used to enforce policies, filter content, cache data, or improve performance.



### 4.4 List the differences in HTTP headers after setting up the proxy. What has changed?

Before:

```bash
vagrant@lab2:~$ curl -I lab3
HTTP/1.1 200 OK
Date: Thu, 21 Mar 2024 19:20:19 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Thu, 21 Mar 2024 17:04:30 GMT
ETag: "29af-6142eb36402d0"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
```

After:

```bash
vagrant@lab2:~$ curl -I lab3
HTTP/1.1 200 OK
Date: Thu, 21 Mar 2024 20:01:41 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Thu, 21 Mar 2024 19:45:47 GMT
ETag: "29af-61430f4238dbe"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
X-Cache: MISS from lab1
X-Cache-Lookup: MISS from lab1:3128
Via: 1.1 lab1 (squid/5.7)
Connection: keep-alive



vagrant@lab2:~$ curl -I lab3
HTTP/1.1 200 OK
Date: Thu, 21 Mar 2024 20:15:37 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Thu, 21 Mar 2024 19:45:47 GMT
ETag: "29af-61430f4238dbe"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
Age: 2
X-Cache: HIT from lab1
X-Cache-Lookup: HIT from lab1:3128
Via: 1.1 lab1 (squid/5.7)
Connection: keep-alive

```

After after:

```bash
vagrant@lab2:~$ curl -I lab3
HTTP/1.1 502 Bad Gateway
Server: squid/5.7
Mime-Version: 1.0
Date: Thu, 21 Mar 2024 20:11:09 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 3417
X-Squid-Error: ERR_READ_ERROR 0
Vary: Accept-Language
Content-Language: en
X-Cache: MISS from lab1
X-Cache-Lookup: MISS from lab1:3128
Via: 1.1 lab1 (squid/5.7)
Connection: keep-alive
```

- The response header has an additional line: `Via: 1.1 lab1 (squid/4.10)`, which indicates that the response was processed by squid on lab1.
- The response header has an additional line: `X-Cache: MISS from lab1`, which indicates that the response was not cached by squid on lab1.
- The response header has an additional line: `X-Cache-Lookup: MISS from lab1:3128`, which indicates that squid on lab1 did not find the requested resource in its cache.
- The response header has an additional line: `Age: 103`, which indicates that the response was cached by squid on lab1 for 103 seconds.







## 5 Implement a DMZ

A DMZ (**demilitarized zone**) network is a physical or logical subnet that separates an internal local area network (LAN) from other untrusted networks (usually the Internet). The purpose of a DMZ is to add an extra layer of security to an organization's LAN. In this way, each external network node can access only what is provided through the DMZ, and the rest of the organization's network remains behind the firewall. In this task we design a DMZ network with a firewall. Assume your organizations outward facing webserver running on lab2 is in a DMZ and your lab3 is in Internal Network, while lab1 is the firewall host executing the firewall rules as shown below.

 You can use a destination network address translation (DNAT) rule to forward incoming packets on a lab1 port to a port on lab2.

1. On lab1 set up the nftables firewall with 3 network cards. You should forward port 8080 from your host to lab1

   - eth0 is attached to NAT

   - eth1 is attached to DMZ (lab2)

   - eth3 is attached to Internal network (lab3)

2. Add a rule to the prerouting chain that redirects incoming packets on port 8080 to the port 80 on lab2. It means the traffic coming from eth0 will be redirected to eth1. 
3. Add a rule to the postrouting chain to masquerade outgoing traffic.
4. The traffic coming from eth2 to eth 1 would be passed without any problem.
5. eth1 just allows to pass traffic in response to requests that have been made to lab2 in DMZ.
6. On lab2 install Apache web server.



### 5.1 Demonstrate you can browse the Apache webserver from your host and lab3. Demonstrate you cannot ping from lab2 to lab3

```bash
vagrant@lab3:~$ curl -I lab1:8080
HTTP/1.1 200 OK
Date: Thu, 21 Mar 2024 22:41:06 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Thu, 21 Mar 2024 22:34:00 GMT
ETag: "29af-614334dbd4043"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html

vagrant@lab3:~$ curl -I lab2
HTTP/1.1 200 OK
Date: Thu, 21 Mar 2024 22:41:21 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Thu, 21 Mar 2024 22:34:00 GMT
ETag: "29af-614334dbd4043"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
```





### 5.2 List the commands you used to set up the DMZ in nftables. You must show the prerouting, postrouting , forward, input and output chains.

```bash
sudo nft add table ip nat

sudo nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }


sudo nft add rule ip nat prerouting tcp dport 8080 dnat to 192.168.0.3:80

sudo nft add chain ip nat postrouting { type nat hook postrouting priority 0 \; }

sudo nft add rule ip nat postrouting oif enp0s3 masquerade



sudo nft add table inet filter

sudo nft add chain inet filter input { type filter hook input priority 0 \; policy drop\; }

sudo nft add chain inet filter output { type filter hook output priority 0 \; policy drop\; }


sudo nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop\; }




sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter input tcp sport 80 accept
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input tcp dport 8080 accept

sudo nft add rule inet filter output oif lo accept
sudo nft add rule inet filter output tcp dport 80 accept
sudo nft add rule inet filter output tcp sport 22 accept
sudo nft add rule inet filter output tcp sport 8080 accept


sudo nft add rule inet filter forward iif enp0s9 oif enp0s8 ct state new,related,established accept
sudo nft add rule inet filter forward iif enp0s8 oif enp0s9 ct state related,established accept
```

