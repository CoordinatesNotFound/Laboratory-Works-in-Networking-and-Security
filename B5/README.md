# B5: VPN





## 0 Introduction

> Additional Reading:
>
> - [OpenVPN HOWTO](http://openvpn.net/index.php/open-source/documentation/howto.html)
> - [How to Create Keys](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-18-04)



### 0.1 Motivation

*The government is spying on your internet use. Hackers are spying on you. Use VPN to protect yourself. Service providers are blocking overseas customers. Use VPN to bypass this.*

You may have heard statements like the ones above from tech news, your favourite streamer or podcaster and VPN advertisements. VPNs can be used as proxies to hide the origin of web traffic by routing traffic through a VPN server in another location. They can also be used to hide your traffic from prying eyes by encrypting the traffic between your computer and the VPN server and burying the traffic into the massive flood of traffic going to and from the VPN server on the other end of the tunnel.

In this assignment, however, you will create a VPN bridge, that allows you to access a LAN network from the outside, as if the computer was a part of that network. You will provide an IP address from said network for the computer. This method can be used for accessing e.g. a corporate network over the internet.



### 0.2 Description

This assignment introduces you to the Virtual Private Network (VPN) concept. You will use OpenVPN and all three VMs to establish a VPN in practice by creating and examining a host-to-net VPN scenario. A roadwarrior host (lab3, RW) establishes a secure tunnel to a gateway (lab1, GW). Traffic can flow from the roadwarrior through the gateway to a Storage server (lab2, SS) and back. Hosts on the right-side local link can not eavesdrop or modify the traffic flowing inside the tunnel. Here’s what the resulting network will look like.

The goal of this assignment is to test communication between the Storage Server and the Road Warrior by successfully pinging and tracerouting each other in both directions. OpenVPN will be used in bridging mode to connect the RW to the local network of SS and GW.



## 1 Initial Setup







### 1.1 Present your network configuration. What IPs did you assign to the interfaces (4 interfaces in all) of each of the three hosts?

```
GW: 192.168.0.0 192.168.2.2
SS: 192.168.0.3
RW: 192.168.2.3
```







## 2 Setting up a PKI (Public Key Infrastructure)

The first step in establishing an OpenVPN connection is to build the public key infrastructure (PKI).

You'll need to generate the master Certificate Authority (CA) certificate/key, the server certificate/key and a key for at least one client. In addition you also have to generate the Diffie-Hellman parameters for the server. Note: the Ubuntu openvpn package no longer ships with easy-rsa.

After you have generated all the necessary certificates and keys, copy the necessary files (securely) to the road warrior (RW) host.



On lab1:

Install easyrsa

```bash
wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
tar xvf EasyRSA-3.0.8.tgz
mv EasyRSA-3.0.8.tgz CA
tar xvf EasyRSA-3.0.8.tgz
mv EasyRSA-3.0.8.tgz Server
```

Set up PKI

```bash
cd ~/CA/

cp vars.example vars

nano vars
# edit the field

./easyrsa init-pki

# build CA PKI
./easyrsa build-ca nopass
```

Creating the Server Certificate, Key, and Encryption Files:
```bash
cd ~/Server/

./easyrsa init-pki

./easyrsa gen-req server nopass

sudo cp pki/private/server.key /etc/openvpn/

sudo cp pki/reqs/server.req ~/CA/

cd ~/CA/

sudo ./easyrsa import-req server.req server

# sign the server certificate
sudo ./easyrsa sign-req server server

sudo cp pki/issued/server.crt ~/Server/

sudo cp pki/ca.crt ~/Server/

cd ~/Server/

sudo cp {server.crt,ca.crt} /etc/openvpn/

# ========

# generate Diffie-Hellman key
./easyrsa gen-dh

# generate an HMAC signature to strengthen the server’s TLS integrity verification capabilities
openvpn --genkey secret ta.key

sudo cp ta.key /etc/openvpn/
sudo cp pki/dh.pem /etc/openvpn/
```

Generating a Client Certificate and Key Pair

```bash
mkdir -p ~/client-configs/keys

chmod -R 700 ~/client-configs

cd ~/Server/

./easyrsa gen-req client1 nopass

sudo cp pki/private/client1.key ~/client-configs/keys/

sudo cp pki/reqs/client1.req ~/CA/

cd ~/CA/

/easyrsa import-req client1.req client1

./easyrsa sign-req client client1

sudo cp pki/issued/client1.crt ~/Server/

cd ~/Server/

sudo cp client1.crt ~/client-configs/keys/

sudo cp ta.key ~/client-configs/keys/

sudo cp ca.crt ~/client-configs/keys/
```







### 2.1  What is the purpose of each of the generated files? Which ones are needed by the client?

- `ca.crt`/`ca.key` - Master Certificate Authority (CA) certificate/key: the root certificate/key that is used to sign all other certificates in the PKI. It is used to establish trust between the OpenVPN server and the clients.
- `server.crt`/`server.key` - Server certificate/key: used by the OpenVPN server to authenticate itself to the clients.
- `client1.crt`/`client1.key` - Client certificate/key: used by the OpenVPN clients to authenticate themselves to the server.
- `dh.pem` - Diffie-Hellman (DH) parameters: These parameters are used to establish the initial encryption key that is used for the OpenVPN connection.
- `ta.key` - HMac signature: to strengthen the server’s TLS integrity verification capabilities

Needed by the client:

- Client certificate/key
- CA certificate
- HMac signature key.



### 2.2  Is there a simpler way of authentication available in OpenVPN? What are its benefits/drawbacks? 

Yess, there is a simpler way of authentication available in OpenVPN called "static key authentication". In this method, a pre-shared secret key is used instead of a PKI.

- Benefits: cheaper, lower overhead
- Drawbacks: not that secure



## 3 Configuring the VPN server

On GW copy */usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz* to for example */etc/openvpn* and extract it. You have to edit the *server.conf* to use bridged mode with the correct virtual interface. You also have to check that the keys and certificates point to the correct files. Set the server to listen for connection in GW's enp0s9 IP address.

Start the server on GW with *openvpn server.conf* .





```bash
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/

sudo nano /etc/openvpn/server.conf
# edit server.conf

sudo systemctl start openvpn@server

# sudo systemctl status openvpn@server

# ip addr show tap0

sudo systemctl enable openvpn@server
```







### 3.1 List and give a short explanation of the commands you used in your server configuration.

```bash
# Which local IP address should OpenVPN
# listen on? (optional)
local 192.168.2.2


# Which TCP/UDP port should OpenVPN listen on?
# If you want to run multiple OpenVPN instances
# on the same machine, use a different port
# number for each one.  You will need to
# open up this port on your firewall.
port 1194

# TCP or UDP server?
;proto tcp
proto udp

# "dev tun" will create a routed IP tunnel,
# "dev tap" will create an ethernet tunnel.
# Use "dev tap0" if you are ethernet bridging
# and have precreated a tap0 virtual interface
# and bridged it with your ethernet interface.
# If you want to control access policies
# over the VPN, you must create firewall
# rules for the the TUN/TAP interface.
# On non-Windows systems, you can give
# an explicit unit number, such as tun0.
# On Windows, use "dev-node" for this.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
dev tap0
;dev tun


# SSL/TLS root certificate (ca), certificate
# (cert), and private key (key).  Each client
# and the server must have their own cert and
# key file.  The server and all clients will
# use the same ca file.
#
# See the "easy-rsa" directory for a series
# of scripts for generating RSA certificates
# and private keys.  Remember to use
# a unique Common Name for the server
# and each of the client certificates.
#
# Any X509 key management system can be used.
# OpenVPN can also use a PKCS #12 formatted key file
# (see "pkcs12" directive in man page).
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret

# Diffie hellman parameters.
# Generate your own with:
#   openssl dhparam -out dh2048.pem 2048
dh dh.pem

# Configure server mode and supply a VPN subnet
# for OpenVPN to draw client addresses from.
# The server will take 10.8.0.1 for itself,
# the rest will be made available to clients.
# Each client will be able to reach the server
# on 10.8.0.1. Comment this line out if you are
# ethernet bridging. See the man page for more info.
;server 10.8.0.0 255.255.255.0


# Configure server mode for ethernet bridging.
# You must first use your OS's bridging capability
# to bridge the TAP interface with the ethernet
# NIC interface.  Then you must manually set the
# IP/netmask on the bridge interface, here we
# assume 10.8.0.4/255.255.255.0.  Finally we
# must set aside an IP range in this subnet
# (start=10.8.0.50 end=10.8.0.100) to allocate
# to connecting clients.  Leave this line commented
# out unless you are ethernet bridging.
server-bridge 192.168.0.2 255.255.255.0 192.168.0.50 192.168.0.100

# For extra security beyond that provided
# by SSL/TLS, create an "HMAC firewall"
# to help block DoS attacks and UDP port flooding.
#
# Generate with:
#   openvpn --genkey tls-auth ta.key
#
# The server and each client must have
# a copy of this key.
# The second parameter should be '0'
# on the server and '1' on the clients.
tls-auth ta.key 0 # This file is secret

# Select a cryptographic cipher.
# This config item must be copied to
# the client config file as well.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the ncp-cipher option in the manpage
cipher AES-256-CBC
```







### 3.2 What IP address space did you allocate to the OpenVPN clients?

```
192.168.0.2 255.255.255.0 192.168.0.50 192.168.0.100
```





### 3.3 Where can you find the log messages of the server by default? How can you change this?

The log messages of the OpenVPN server are typically stored in the syslog `/var/log/openvpn/openvpn.log`on Linux systems. However, the location can be changed by modifying the "status", "log", "log-append" option in the OpenVPN server configuration file. Additionally, the "verb" option can be used to control the verbosity of the log messages.



## 4 Bridging setup

Next you have to setup network bridging on the GW. We'll combine the enp0s8 interface of the gateway with a virtual TAP interface and bridge them together under an umbrella bridge interface.

OpenVPN provides a script for this in */usr/share/doc/openvpn/examples/sample-scripts* . Copy the bridge-start and the bridge-stop scripts to a different folder for editing. Edit the parameters of the script files to match with GW's enp0s8. Start the bridge and check with *ifconfig* that the bridging was successful.



Copy the scripts:
```bash
sudo cp /usr/share/doc/openvpn/examples/sample-scripts/bridge-start /etc/openvpn

sudo cp /usr/share/doc/openvpn/examples/sample-scripts/bridge-stop /etc/openvpn
```

Modify bridge-start:
```bash
sudo sed -i 's/eth0/enp0s8/g' /etc/openvpn/bridge-start
sudo sed -i 's/192.168.8./192.168.0./g' /etc/openvpn/bridge-start
sudo sed -i 's/192.168.0.4/192.168.0.2/g' /etc/openvpn/bridge-start
```

Start bridging:
```bash
sudo /etc/openvpn/bridge-start
```





### 4.1 Show with ifconfig that you have created the new interfaces (virtual and bridge). What's the IP of the bridge interface?

```
br0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.2  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 fe80::d84e:57ff:fe18:49be  prefixlen 64  scopeid 0x20<link>
        ether da:4e:57:18:49:be  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 15  bytes 1274 (1.2 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


tap0: flags=4355<UP,BROADCAST,PROMISC,MULTICAST>  mtu 1500
        ether e6:93:cb:2a:0e:2a  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

192.168.0.2





### 4.2  What is the difference between routing and bridging in VPN? What are the benefits/disadvantages of the two? When would you use routing and when bridging?

**Routing:**

- **Definition**: In routing, VPN traffic is routed between networks using IP routing protocols. Each VPN client is assigned an IP address within the VPN subnet, and routing tables are used to direct traffic between the client and the VPN server.
- **Benefits**:
  - Scalability: Routing can be more scalable, because it can handle a larger network with many connected devices and networks
  - Security: Routing can provide better isolation between VPN clients, because it enables traffic filtering, traffic shaping, and access control.

- **Disadvantages**:
  - Complex Configuration: Setting up routing VPNs may require more configuration and management compared to bridging, especially for more complex network topologies.
  - Limited Broadcast and Multicast Support: Routing may have limitations with broadcast and multicast traffic, which may not be easily forwarded between VPN clients.

**Bridging:**

- **Definition**: Bridging is the process of forwarding packets of data between two network segments at the data-link layer. In VPN, bridging involves creating a virtual network interface that combines multiple physical interfaces into a single logical interface. All traffic is then forwarded between the virtual interface and the physical interfaces. Each VPN client becomes a part of the same broadcast domain as the VPN server, and VPN traffic is forwarded using MAC addresses.

- **Benefits**:

  - Simplified Configuration: Bridging can be easier to configure, especially for small networks, as it extends the local network to remote clients without requiring complex routing configurations.

  - Full Layer 2 Connectivity: Bridging allows you to connect multiple devices and networks as if they were on the same LAN.
  - Better Broadcast Support: more useful for broadcast

- **Disadvantages**:

  - Less Security: Not that secure, as it may not support advanced security policies such as traffic filtering, traffic shaping, and access control.

  - Limited Scalability: Bridging may not scale well for large networks with many clients, as it requires the VPN server to handle bridging for each client, which can impact server performance.

**When to Use Routing vs Bridging**:

- **Routing**: Use routing when scalability, security, and flexibility are the primary concerns. Routing is suitable for large networks with many clients, especially when clients need to be isolated from each other and when complex network configurations are required.
- **Bridging**: Use bridging when simplicity and full Layer 2 connectivity are desired. Bridging is suitable for small networks or situations where clients need to be on the same broadcast domain and network configuration complexity is to be minimized.





## 5 Configuring the VPN client and testing connection

On RW copy */usr/share/doc/openvpn/examples/sample-config-files/client.conf* to for example */etc/openvpn*. Edit the *client.conf* to match with the settings of the server. Remember to check that the certificates and keys point to the right folders.

Connect RW to the server on GW with openvpn *client.conf*. Pinging the SS from RW should now work.

If you have problems with the ping not going through, go to VirtualBox network adapter settings and allow promiscuous mode for internal networks that need it.



On lab1:

Configure client:

```bash
cd ~/Server/

mkdir -p ~/client-configs/files

cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

nano ~/client-configs/base.conf
# edit base.conf

nano ~/client-configs/make_config.sh

# edit with:
#!/bin/bash

# First argument: Client identifier

KEY_DIR=/home/vagrant/client-configs/keys
OUTPUT_DIR=/home/vagran/client-configs/files
BASE_CONFIG=/home/vagran/client-configs/base.conf


cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn
    
    
    
chmod 700 ~/client-configs/make_config.sh

cd ~/client-configs
sudo ./make_config.sh client1

scp files/client1.ovpn vagrant@lab3:~/
```

On lab3:
run client:

```bash
sudo openvpn --config client1.ovpn
```





### 5.1 List and give a short explanation of the commands you used in your VPN client configuration.

```bash
# Use the same setting as you are using on
# the server.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
;dev tap0
dev tun

# Are we connecting to a TCP or
# UDP server?  Use the same setting as
# on the server.
;proto tcp
proto udp

# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote lab1 1194
;remote my-server-2 1194

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair
# for each client.  A single ca
# file can be used for all clients.
ca ca.crt
cert client1.crt
key client1.key

# Verify server certificate by checking that the
# certificate has the correct key usage set.
# This is an important precaution to protect against
# a potential attack discussed here:
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the keyUsage set to
#   digitalSignature, keyEncipherment
# and the extendedKeyUsage to
#   serverAuth
# EasyRSA can do this for you.
remote-cert-tls server

# If a tls-auth key is used on the server
# then every client must also have the key.
tls-auth ta.key 1

# Select a cryptographic cipher.
# If the cipher option is used on the server
# then you must also specify it here.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the data-ciphers option in the manpage
cipher AES-256-CBC
```



### 5.2 Demonstrate that you can reach the SS from the RW. Setup a server on the client with netcat and connect to this with telnet/nc. Send messages to both directions.

On lab2

```bash
nc -l 5000
```

On lab3:
```bash
telnet lab2 5000
```



### 5.3 Capture incoming/outgoing traffic on GW's enp0s9 or RW's enp0s8. Why can't you read the messages sent in 5.2 (in plain text) even if you comment out the cipher command in the config-files?

On lab1:

Command:
```bash
sudo tcpdump -i enp0s9
```

Result:

```bash
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), snapshot length 262144 bytes
00:14:09.489064 IP lab3.54402 > lab1.openvpn: UDP, length 40
00:14:09.489320 IP lab1.openvpn > lab3.54402: UDP, length 40
00:14:14.707534 ARP, Request who-has lab3 tell lab1, length 28
00:14:14.707909 ARP, Reply lab3 is-at 08:00:27:31:f3:37 (oui Unknown), length 46
00:14:19.594629 IP lab3.54402 > lab1.openvpn: UDP, length 40
00:14:19.594784 IP lab1.openvpn > lab3.54402: UDP, length 40
00:14:24.820469 ARP, Request who-has lab1 tell lab3, length 46
00:14:24.820490 ARP, Reply lab1 is-at 08:00:27:02:bf:13 (oui Unknown), length 28
00:14:29.811150 IP lab3.54402 > lab1.openvpn: UDP, length 40
00:14:29.811273 IP lab1.openvpn > lab3.54402: UDP, length 40
00:14:39.851479 IP lab3.54402 > lab1.openvpn: UDP, length 40
00:14:39.851746 IP lab1.openvpn > lab3.54402: UDP, length 40
00:14:44.479237 IP lab3.54402 > lab1.openvpn: UDP, length 98
00:14:44.479986 IP lab1.openvpn > lab3.54402: UDP, length 98
00:14:44.480396 IP lab3.54402 > lab1.openvpn: UDP, length 90
00:14:47.763591 IP lab3.54402 > lab1.openvpn: UDP, length 103
00:14:47.764377 IP lab1.openvpn > lab3.54402: UDP, length 90
00:14:49.651886 IP lab3.54402 > lab1.openvpn: UDP, length 66
00:14:49.652571 IP lab1.openvpn > lab3.54402: UDP, length 84
00:14:49.655642 ARP, Request who-has lab1 tell lab3, length 46
00:14:49.655652 ARP, Reply lab1 is-at 08:00:27:02:bf:13 (oui Unknown), length 28
00:14:50.499849 IP lab3.54402 > lab1.openvpn: UDP, length 90
00:14:50.500774 IP lab1.openvpn > lab3.54402: UDP, length 90
00:14:50.501426 IP lab3.54402 > lab1.openvpn: UDP, length 90
00:15:00.590672 IP lab3.54402 > lab1.openvpn: UDP, length 40
00:15:00.590975 IP lab1.openvpn > lab3.54402: UDP, length 40
```

Because after openVPN v2.4 client/server will automatically negotiate AES-256-GCM in TLS mode, the OpenVPN protocol encapsulates the messages inside encrypted packets using SSL/TLS encryption. The messages are only decrypted on the receiving end after going through the OpenVPN encryption and decryption process.



### 5.4 Enable ciphering. Is there a way to capture and read the messages sent in 5.2 on GW despite the encryption? Where is the message encrypted and where is it not?

Yes, as enabling ciphering in the OpenVPN configuration will only encrypt the messages being sent between the client and the server using SSL/TLS encryption. The encryption only happens on the client-side after sending the messages and on the server-side before receiving the messages. Therefore, if we capture the packets using a packet capture tool like tcpdump or Wireshark at br0, enp0s8, we are able to read the messages in plain text.

Also, as we store certificates on GW (lab1), we have the correct encryption keys or certificates, so we can also decrypt the captured packets and read the messages in plain text. This can be done using Wireshark's SSL/TLS decryption feature. By providing the decryption keys or certificates, Wireshark can decrypt the captured packets and display the contents in plain text.





### 5.5 Traceroute RW from SS and vice versa. Explain the result.

```bash
# lab3 -> lab2
traceroute to lab2 (192.168.0.3), 64 hops max
  1   192.168.0.3  0.875ms  0.621ms  0.641ms

# lab2 -> lab3
traceroute to lab3 (192.168.2.3), 64 hops max
  1   10.0.2.2  0.096ms  0.109ms  0.099ms
  2   *  *  *
  3   *  *  *
```

The result of the traceroute command indicates that the destination host "lab2" with IP address 192.168.0.3 was reached within a single hop. This suggests that the source host and the destination host are on the same local network segment, and there are no intermediate routers or gateways that the packets need to pass through to reach the destination with VPN. Therefore, the packets can be sent directly from the source host to the destination host with minimal latency.



## 6 Setting up routed VPN

In this task, you have to set up routed VPN as opposed to the bridged VPN above. Stop openvpn service on both server and client.

1. Reconfigure the server.conf and the client.conf to have routed vpn.

   - server.conf
     ```bash
     ;dev tap0
     dev tun
     
     server 10.8.0.0 255.255.255.0
     
     ;server-bridge 192.168.0.2 255.255.255.0 192.168.0.50 192.168.0.100
     ```

   - client.conf
     ```bash
     ;dev tap0
     dev tun
     ```

2. Restart openvpn service on both server and client.
   ```bash
   sudo systemctl stop openvpn@server
   sudo /etc/openvpn/bridge-stop
   sudo cp ~/Server/tmp/server-routed.conf /etc/openvpn/server.confs
   sudo systemctl start openvpn@server
   ```

3. Now you should be able to ping virtual IP address of vpn server from client.
   ```bash
   ping 10.8.0.1
   ```

   

### 6.1 List and give a short explanation of the commands you used in your server configuration

```bash
;dev tap0
dev tun

server 10.8.0.0 255.255.255.0

;server-bridge 192.168.0.2 255.255.255.0 192.168.0.50 192.168.0.100
```





### 6.2 Show with ifconfig that you have created the new virtual IP interfaces . What's the IP address?

10.8.0.1

