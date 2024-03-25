# A1 & B1: Setting up and Networking tools



## 0 Setting up the networks and virtual machines



### 0.1 Setting up virtual machines

1. Download VirtualBox installer for your operating system from https://www.virtualbox.org/wiki/Downloads.

2. Install VirtualBox.

3. Download the Ubuntu server LTS 22.04 image from: https://releases.ubuntu.com/22.04/

4. From VirtualBox, create 3 new virtual machines with settings:

   - Type: Linux
   - Version: Ubuntu (64-bit)
   - Memory size: at least 1024MB, note your host computer's available RAM
   - Create a dynamically allocated virtual hard disk: VDI (VirtualBox Disk Image)
   - Virtual hard disk size: 4 - 8Gt depending on your available Hard disk space (you'd better set it 8G)

5. Set up one NAT network. Go to File / Preferences / Network / NAT networks and create a new network. Make sure DHCP is enabled.

   > NB. Unless other wise mentioned, the NAT network is used only to adminster your VMs and to allow download and installation of tools to your VM.

6. Set up the networks in virtual machines. Right-click on VM, select Settings and Network tab.

   - For VM 1 Adapter 1: NatNetwork, Adapter 2: Internal network (intnet1), Adapter 3: Internal network (intnet2)
   - For VM 2 Adapter 1: NatNetwork, Adapter 2: Internal network (intnet1)
   - For VM 3 Adapter 1: NatNetwork, Adapter 2: Internal network (intnet2)

7. Insert the Ubuntu server image to all VMs optical drives. Go to VM Settings / Storage / Controller IDE / Click Empty and click Optical Drive disk button. Search the image that you downloaded and open. Do this for all the VMs.

8. Start the VMs simultaneously and install them in parallel. Installing the VMs separately instead of cloning them ensures that we have separate configuration on each VM, like hostnames and IP addresses.

9. During the installation procedure, you will be asked a lot of things. You should be familiar with installing an operating system at this point. If you are not confident enough to answer the questions in the installation process, now would be a good time to study those things. The installation process will also ask for the hostname of the VM. Type in:

   - VM 1: lab1
   - VM 2: lab2
   - VM 3: lab3

10. When asked about what packages to install, select OpenSSH server to be able to connect to your machines.

11. Set up port forwarding to be able to bypass the NAT. Go to File / Preferences / Network / NAT networks and edit your NatNetwork. Select Port Forwarding and do the following rules:

    - Rule 1, TCP, Host IP and port 127.0.0.1:10001, Guest IP and port [your lab1 IP]:22
    - Rule 2, TCP, Host IP and port 127.0.0.1:10002, Guest IP and port [your lab2 IP]:22
    - Rule 3, TCP, Host IP and port 127.0.0.1:10003, Guest IP and port [your lab3 IP]:22

    > Use `ip addr show` in each VM to check the ip address

12. You are done. You can start doing the assignments. Remember that there is no DHCP server in intnet1 and intnet2. You have to do the configuration on those interfaces manually. You should not use the VirtualBox view to use the VMs - instead use SSH (localhost ports 10001-10003) to connect to the machines. This way you get similar access to the VMs as in any cloud service.

    > For example, connect to lab1 via `ssh username@127.0.0.1 -p 10001`

    

> Additional Reading:
>
> - netcat(1) 
> - ssh-keygen(1)
> - ip(8)
> - arp(8)
> - dig(1)
> - ping(8)
> - traceroute(1)
> - mtr(8) 
> - nmap(1)
> - nc(1)



## 1 Connecting to virtual machines



### 1.1 Create yourself a key-pair to be used with the virtual machines. See *ssh-keygen(1)* for help

1. Use `ssh-keygen -t ed25519 -C "yinan.hu@aalto.fi"` to generate a key pair, locally, based on ED25519
2. From local, use `ssh yinan@127.0.0.1 -p [10001-10003]` and input the correct password to connect to each VM
3. In each VM, copy the locally generated public key (id_rsa.pub) to the `~/.ssh/authorized_keys`, now you can connect to VMs from local without inputting username and password!
4. Copy the private key (id_rsa) to lab1, so you can connect from lab1 to lab2&lab3 without password
5. You should grant write authority to ~/.ssh/*, via `chmod 600 ~/.ssh/*`



## 2 Networking basics



### 2.1 Using *ip(8)*, find all the active interfaces on your machine

Command:

```shell
ip link
```

Result:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 02:64:7d:6d:e2:30 brd ff:ff:ff:ff:ff:ff
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:51:71:43 brd ff:ff:ff:ff:ff:ff
4: enp0s9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:6b:fc:9d brd ff:ff:ff:ff:ff:ff
```



### 2.2 Using *ip(8)* and *arp(8)*, find the MAC address of the default router of your machine

Command:
```shell
ip route
arp -n <ip_address>
```

Result:

```
Address                  HWtype  HWaddress           Flags Mask            Iface
10.0.2.2                 ether   52:54:00:12:35:02   C                     enp0s3
```





### 2.3 From *resolv.conf(5)*, find the default name servers and the internet domain of your machine. How is this file generated?

Command:

```
cat /etc/resolv.conf
```

Result:

```
# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients to the
# internal DNS stub resolver of systemd-resolved. This file lists all
# configured search domains.
#
# Run "resolvectl status" to see details about the uplink DNS servers
# currently in use.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 127.0.0.53
options edns0 trust-ad
search .
```

name servers:

```
127.0.0.53
```

internet domain

```
.
```

resolv.conf is automatically generated by various network configuration and management tools. It is used for configuring DNS, so the local clients can connect to the DNS stub resolver. It contains all search domain.



### 2.4 Using *dig(1)*, find the responsible name servers for the cs.hut.fi domain

Command:
```shell
dig NS cs.hut.fi +short
```

Result:

```
ns.niksula.hut.fi.
sauna.cs.hut.fi.
```



### 2.5 Using *dig(1)*, find the responsible mail exchange servers for cs.hut.fi domain

Command:

```
dig MX cs.hut.fi +short
```

Result:
```
1 mail.cs.hut.fi.
```





### 2.6 Using *ping(8)*, send 5 packets to aalto.fi and find out the average latency. Try then pinging Auckland University of Technology, aut.ac.nz, and see if the latency is different

Command:

```shell
ping -c 5 aalto.fi
ping -c 5 aut.ac.nz
```

Result:

```
# ping -c 5 aalto.fi
PING aalto.fi (104.17.222.22) 56(84) bytes of data.
64 bytes from 104.17.222.22 (104.17.222.22): icmp_seq=1 ttl=54 time=25.6 ms
64 bytes from 104.17.222.22 (104.17.222.22): icmp_seq=2 ttl=54 time=15.7 ms
64 bytes from 104.17.222.22 (104.17.222.22): icmp_seq=3 ttl=54 time=17.7 ms
64 bytes from 104.17.222.22 (104.17.222.22): icmp_seq=4 ttl=54 time=19.7 ms
64 bytes from 104.17.222.22 (104.17.222.22): icmp_seq=5 ttl=54 time=16.1 ms

--- aalto.fi ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4007ms
rtt min/avg/max/mdev = 15.671/18.977/25.641/3.621 ms

# ping -c 5 aut.ac.nz
PING aut.ac.nz (156.62.238.90) 56(84) bytes of data.
64 bytes from bax.aut.ac.nz (156.62.238.90): icmp_seq=1 ttl=37 time=342 ms
64 bytes from bax.aut.ac.nz (156.62.238.90): icmp_seq=2 ttl=37 time=341 ms
64 bytes from bax.aut.ac.nz (156.62.238.90): icmp_seq=3 ttl=37 time=310 ms
64 bytes from bax.aut.ac.nz (156.62.238.90): icmp_seq=4 ttl=37 time=312 ms
64 bytes from bax.aut.ac.nz (156.62.238.90): icmp_seq=5 ttl=37 time=308 ms

--- aut.ac.nz ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4002ms
rtt min/avg/max/mdev = 308.334/322.787/342.454/15.418 ms
```

It's different. The average latency of aalto.fi ping is 18.977 ms, while the average latency of aut.ac.nz ping is 322.787 ms



### 2.7 Using traceroute(1), find out how many hops away is amazon.com. Why does this address sometimes produce different results on different traceroute runs?
Command:

```shell
traceroute -I amazon.com
```

Result:
```
traceroute to amazon.com (52.94.236.248), 30 hops max, 60 byte packets
 1  _gateway (10.0.2.1)  0.234 ms  0.066 ms  0.127 ms
 2  10.100.0.1 (10.100.0.1)  3.116 ms  3.051 ms  3.109 ms
 3  jgw-2-v100.aalto.fi (130.233.231.19)  4.087 ms  4.025 ms  4.154 ms
 4  funet-100g-aalto-a.aalto.fi (130.233.231.189)  4.090 ms  4.112 ms  4.174 ms
 5  espoo1.ip.funet.fi (86.50.255.232)  3.831 ms  4.193 ms  4.184 ms
 6  fi-csc.nordu.net (109.105.102.168)  4.115 ms  2.307 ms  2.491 ms
 7  de-hmb.nordu.net (109.105.97.77)  32.466 ms  29.979 ms  30.013 ms
 8  nl-ams.nordu.net (109.105.97.80)  39.096 ms  39.090 ms  39.241 ms
 9  us-man.nordu.net (109.105.97.64)  121.768 ms  121.759 ms  121.797 ms
10  nyiix-peering.amazon.com (198.32.160.64)  121.868 ms  121.982 ms  121.943 ms
11  150.222.68.80 (150.222.68.80)  121.809 ms  121.801 ms  121.559 ms
12  150.222.68.83 (150.222.68.83)  134.674 ms  129.667 ms  123.998 ms
13  * * *
14  150.222.68.66 (150.222.68.66)  110.349 ms  120.254 ms  120.177 ms
15  * * *
16  * * *
17  * * *
18  * * *
19  * * *
20  * * *
21  * * *
22  * * *
23  * * *
24  * * *
25  52.94.236.248 (52.94.236.248)  115.112 ms  115.210 ms  133.942 ms
```

Because the network conditions varies and Large services like Amazon often use load balancing to distribute traffic across multiple servers, the route of the packages can be different each time.



### 2.8 Using mtr(8) find out the minimum, maximum and average network latency between your machine and google.com. Can the packet loss% be greater than 0 even if there is no loss in transport layer traffic? Why?

Command:
```shell
mtr google.com -c 15
```

Result:

```
                                                 My traceroute  [v0.95]
lab1 (10.0.2.15) -> google.com (142.250.74.78)                                                 2024-01-18T14:31:55+0000
 Loss%   Snt   Last   Avg  Best  Wrst StDevtics   Order of fields   quit
                                                                               Packets               Pings
 Host                                                                        Loss%   Snt   Last   Avg  Best  Wrst StDev
 1. _gateway                                                                  0.0%    15    0.5   0.7   0.5   1.1   0.1
 2. 10.100.0.1                                                                0.0%    15    6.1   7.5   3.1  17.3   4.4
 3. jgw-2-v100.aalto.fi                                                       0.0%    15    5.4  10.2   3.0  47.4  10.8
 4. funet-100g-aalto-a.aalto.fi                                               0.0%    15    3.0  12.2   3.0  42.6  10.7
 5. espoo1.ip.funet.fi                                                        0.0%    15    3.5   7.5   3.5  18.9   4.5
 6. fi-csc.nordu.net                                                          6.7%    15    3.5  28.2   3.1 311.6  81.6
 7. se-tug.nordu.net                                                          0.0%    15   15.3  71.8  15.1 422.2 135.0
 8. se-bma.nordu.net                                                          6.7%    15   16.2  50.7  14.9 300.3  82.9
 9. google-gw.nordu.net                                                      13.3%    15   16.8  41.1  15.6 307.9  80.2
10. 142.250.213.135                                                           0.0%    15   16.5  54.5  14.9 406.1 106.0
11. 142.251.65.83                                                             0.0%    15   18.8  46.4  15.4 324.9  80.1
12. arn09s23-in-f14.1e100.net                                                 0.0%    15   19.6  36.1  14.9 224.6  52.5
```

Yes, it's possible for the reported packet loss percentage to be greater than 0 even if there is no loss in transport layer traffic. The reason for this discrepancy is often related to how routers and network devices handle certain types of traffic.

`mtr` typically uses ICMP (Internet Control Message Protocol) packets to measure latency and packet loss. Some routers and firewalls might prioritize or deprioritize ICMP packets differently from other types of traffic. Therefore, while ICMP packets may experience loss or delays, actual data packets (e.g., TCP or UDP packets) might not encounter the same issues.

In summary, the reported packet loss from `mtr` is specific to ICMP traffic and may not accurately reflect the behavior of other types of traffic at the transport layer (e.g., TCP or UDP). Different network devices along the route may treat ICMP packets differently than regular data packets, leading to variations in reported packet loss.



## 3 Scanning networks for devices and ports



### 3.1 Using nmap(1), scan your local network, and show the list of all live and up hosts and open ports on VMs

Command:
```shell
sudo nmap -sT -p- 192.168.1.0/24 192.168.2.0/24
```

Result:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2024-01-15 18:18 UTC
Nmap scan report for lab2 (192.168.1.3)
Host is up (0.00072s latency).
Not shown: 65534 closed ports
PORT   STATE SERVICE
22/tcp open  ssh
MAC Address: 08:00:27:D9:57:3C (Oracle VirtualBox virtual NIC)

Nmap scan report for lab1 (192.168.1.1)
Host is up (0.00020s latency).
Not shown: 65534 closed ports
PORT   STATE SERVICE
22/tcp open  ssh

Nmap scan report for lab3 (192.168.2.3)
Host is up (0.0051s latency).
Not shown: 65534 closed ports
PORT   STATE SERVICE
22/tcp open  ssh
MAC Address: 08:00:27:2B:B5:31 (Oracle VirtualBox virtual NIC)

Nmap scan report for lab1 (192.168.2.1)
Host is up (0.00010s latency).
Not shown: 65534 closed ports
PORT   STATE SERVICE
22/tcp open  ssh

Nmap done: 512 IP addresses (4 hosts up) scanned in 25.33 seconds
```



## 4 Examining the request and response messages of clients and servers using netcat



### 4.1 Using netcat, *nc(1)*, capture the version number of the ssh daemon running on your machine

Command:
```shell
nc localhost 22
```

Result:
```
SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6
```





### 4.2  Using netcat, *nc(1)*, craft a valid HTTP/1.1 request for getting HTTP headers (not the html file itself) from the front page of www.aalto.fi. What request method did you use? Which headers did you need to send to the server? What was the status code for the request? Which headers did the server return? Explain the purpose of each header

Command:
```shell
printf "GET / HTTP/1.1\r\nHost: www.aalto.fi\r\nConnection: close\r\n\r\n" | nc www.aalto.fi 80
```

Result:

```
HTTP/1.1 301 Moved Permanently
Date: Mon, 15 Jan 2024 13:57:55 GMT
Transfer-Encoding: chunked
Connection: close
Cache-Control: max-age=3600
Expires: Mon, 15 Jan 2024 14:57:55 GMT
Location: https://www.aalto.fi/fi
Server: cloudflare
CF-RAY: 845ea16c29f170fb-HEL
```

Details:

- Request
  - request method -  `GET`
  - request headers
    - `Host: www.aalto.fi`: specify the host to be request
    - `Connection: close`: the HTTP/1.1 may keep the connection alive, so we have to close the connection manually
- Response
  - response status code - `301`: the resource requested has been permanently removed to another place.
  - response headers
    - `Date`：specifies the date and time of response
    - `Transfer-Encoding`： indicate the form of encoding that has been applied to the payload body of the message in order to safely transfer it 
    - `Connection`: indicates whether keeping the connection or closing it
    - `Cache-Control`: controls the behavior of cache, for both the server and client
    - `Expires`: specifies the date and time after which the response from the server should be considered stale or expired
    - `Location`: informs the client that the requested resource has been permanently moved to the provided URL
    - `Server`: specifies the type of server (the software)
    - `CF-RAY`: provided by cloudflare, mainly used for tracing the request



### 4.3 Using netcat, nc(1), start a bogus web server listening on the loopback interface port 8080. Verify with netstat(8), that the server really is listening where it should be. Direct your browser lynx(1) to the bogus server and capture the User-Agent: header

Command:

```shell
nc -l 8080
netstat -an | grep 8080
lynx http://127.0.0.1:8080
```

Result:

```
GET / HTTP/1.0
Host: 127.0.0.1:8080
Accept: text/html, text/plain, text/sgml, text/css, */*;q=0.01
Accept-Encoding: gzip, compress, bzip2
Accept-Language: en
User-Agent: Lynx/2.9.0dev.10 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/3.7.1
```



### 4.4 With similar setup to 4.3, start up a bogus ssh server with nc and try to connect to it with *ssh(1)*. Copy-paste the server version string you captured in 4.1 and see if you get a response from the client. What is the client trying to negotiate?

Command

```shell
echo -ne "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6\n" | nc -l -p 2222
ssh -p 2222 localhost
```

Result:

```
SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6
  A}}y qŽA
  1curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,sntrup761x25519-sha512@openssh.com,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256,ext-info-c,kex-strict-c-v00@openssh.com   ssh-ed25519-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp521-cert-v01@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,sk-ecdsa-sha2-nistp256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,sk-ssh-ed25519@openssh.com,sk-ecdsa-sha2-nistp256@openssh.com,rsa-sha2-512,rsa-sha2-256   lchacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com   lchacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com   umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha1-etm@openssh.com,umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-sha1   umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha1-etm@openssh.com,umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-sha1   none,zlib@openssh.com,zlib   none,zlib@openssh.com,zlib
```

It is trying to negotiate the encryption and decryption.



## 5 Vagrant



### 5.0 Vagrant instructions

[Install Vagrant | Vagrant | HashiCorp Developer](https://developer.hashicorp.com/vagrant/tutorials/getting-started/getting-started-install)

[Documentation | Vagrant | HashiCorp Developer](https://developer.hashicorp.com/vagrant/docs)





### 5.1 Which providers does Vagrant support? What does command: \<vagrant init> do?

While Vagrant ships out of the box with support for [VirtualBox](https://www.virtualbox.org/), [Hyper-V](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/about/), and [Docker](https://www.docker.io/), Vagrant has the ability to manage other types of machines as well. This is done by using other *providers* with Vagrant.

`vagrant init` initializes the current directory to be a Vagrant environment by creating an initial [Vagrantfile](https://developer.hashicorp.com/vagrant/docs/vagrantfile) if one does not already exist.



### 5.2 What is box in Vagrant? How do you add a box to the Vagrant environment?

Boxes are the package format for Vagrant environments. You specify a box environment and operating configurations in your Vagrantfile. You can use a box on any supported platform to bring up identical working environments.

You can add a box from the public catalog at any time. The box's description includes instructions on how to add it to an existing Vagrantfile or initiate it as a new environment on the command-line.



### 5.3 Show the provisioning part of your sample code and explain it

See Vagrantfile





### 5.4 Upload a file from your host to a VM. Share a folder on your host to a VM

Command:
```shell
# vagrant plugin install vagrant-scp

vagrant scp <source_file> <host_name>:<target_path>
# e.g. vagrant scp Vagrantfile lab1:/home/vagrant
```



### 5.5 Connect to the running boxes over ssh

Command:
```shell
vagrant ssh <host>
# or ssh vagrant@localhost -p 2222
```



