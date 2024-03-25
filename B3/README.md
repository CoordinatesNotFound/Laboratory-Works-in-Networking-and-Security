## B3: DNS

> Additional Reading:
>
> - [BIND 9 Administrator Reference Manual — BIND 9 9.18.24 documentation](https://bind9.readthedocs.io/en/v9.18.24/)
> - [DNS for Rocket Scientists - Contents](https://www.zytrax.com/books/dns/)
> - [The Basics of DNSSEC - O'Reilly Media](https://web.archive.org/web/20160221185439/http:/www.onlamp.com/pub/a/onlamp/2004/10/14/dnssec.html)
> - [Overview of Pi-hole - Pi-hole documentation](https://docs.pi-hole.net/)



## 0 Inreoduction



### 0.1 Motivation

Devices on the internet are distinguishable from each other by their IP addresses. However, typing an IP address in your browser, e.g. 172.217.21.163 to reach google.com, is tedious and the addresses are difficult to remember. The Domain Name System (DNS) was designed to create an easy to remember naming system to be used instead of IP addresses. Instead of having to type an IP directly, your computer will do a query to a DNS server, finding who in the .com network owns google.com domain, and what IP is assigned to it. A single DNS server cannot store all the name-ip pairs, so DNS operates in a hierarchical manner.

Domain Name Servers are not something only internet service providers can run, but can be created quite easily inside your network as well. Using your own server allows you to create your own domain within your network. This can be used for creating a domain inside a closed corporate network, for example. Storing website-IP address pairs can also reduce the need for higher level queries, speeding up your access to a website. That is why name servers often have a cache of name-address pairs for recently/frequently requested websites.



### 0.2 Description of the exercise

In this exercise you will set up a simple caching-only nameserver, implement your own .insec -domain, complete with a slave server - and finally a subdomain .not.insec, enhanced with DNSSEC. You will also try out [Pi-hole](https://pi-hole.net/) - a DNS sinkhole, which can be used to stop DNS-queries for blacklisted domains.



## 1 Preparation

You will need four virtual machines for this exercise. Begin with assigning suitable host names in */etc/hosts*, for example *ns1,* *ns2**,* *ns3* and client. Install the bind9 package on *ns1* and *ns2* and ns3.





## 2 Caching-only nameserver

Setup *ns1* to function as a caching-only nameserver. It will not be authoritative for any domain, and will only resolve queries on behalf of the clients, and cache the results.

Configure the nameserver to forward all queries for which it does not have a cached answer to Google's public nameserver (8.8.8.8). Only allow queries and recursion from local network.

Start your nameserver and watch the logfile */var/log/syslog* for any error messages. Check that you can resolve addresses through your own nameserver from the client machine. You can use *dig(1)* to do the lookups



### 2.1  Explain the configuration you used.

```
options {
    directory "/var/cache/bind";

    forwarders {
        8.8.8.8;
    };

    recursion yes;
    allow-recursion { localnets; };

    listen-on { 127.0.0.1; 192.168.1.2; };
    allow-query { 127.0.0.1; 192.168.1.0/24; };
};
```

- `directory`: sets the location where the nameserver should store its cache
- `forwarders`: specifies the IP address of the public nameserver (in this case, Google's public DNS server at 8.8.8.8) to which queries for which the nameserver does not have a cached answer should be forwarded
- `allow-recursion` and:  enables the nameserver to accept recursive queries 
-  `allow-query`: allows queries from which address or net.
- `recursion` : enable the nameserver to perform recursive queries on behalf of its clients.



### 2.2 What is a recursive query? How does it differ from an iterative query?

The recursive query returns the final answer, while iterative query forward the query to another name server.





## 3 Create your own tld .insec

Next, you setup your first own domain. This shows that, starting from the top level domains like .com or .fi, all layers of the DNS can also be configured by yourself, to create your very own private internet.

Configure *ns1* to be the primary master for .insec domain. For that you will need to create zone definitions, reverse mappings, and to let your server know it will be authoritative for the zone. Create a zone file for .insec with the following information:

- Primary name server for the zone is ns1.insec
- Contact address should be hostmaster@insec
- Use short refresh and retry time limits of 60 seconds
- Put your machine's ip in ns1.insec's A record

Similarly create a reverse mapping zone *c*.*b*.*a*.in-addr.arpa, where *a*, *b* and *c* are the first three numbers of the virtual machine's current IP address (i.e. IP = *a.b.c.xxx* -> *c.b.a.in-addr.arpa*).

Add a master zone entry for .insec and c.b.a.in-addr.arpa (see above) in *named.conf*. Reload bind's configuration files and watch the log for errors. Try to resolve ns1.insec from your client.



### 3.1 Explain your configuration.

On ns1,

/etc/bind/db.insec:

```
$TTL 60
@       IN      SOA     ns1.insec. hostmaster.insec. (
                        2024021301  ; Serial
                        60          ; Refresh
                        60          ; Retry
                        604800      ; Expire
                        60 )        ; Minimum TTL

@       IN      NS      ns1
ns1     IN      A       192.168.1.2
ns2 IN  A   192.168.1.3
ns3 IN  A   192.168.1.4
client IN  A   192.168.1.5
```

- zone definitions
  - SOA (Start of Authority) record
    - the primary name server for the zone
    - the hostmaster's email address
    - various time limits for refresh, retry, expire, and minimum TTL values.
  - NS (Name Server) record
  - A (Address) record

/etc/bind/1.168.192.in-addr.arpa:

```
$TTL 60
@       IN      SOA     ns1.insec. hostmaster.insec. (
                        2024021301  ; Serial
                        3600        ; Refresh
                        600         ; Retry
                        604800      ; Expire
                        60 )        ; Minimum TTL

@       IN      NS      ns1

192.168.1.2     IN      PTR     ns1
192.168.1.3     IN      PTR     ns2
192.168.1.4     IN      PTR     ns3
192.168.1.5     IN      PTR     client
```

- reverse mapping zone

/etc/bind/named.conf.local:

```
zone "insec" {
	type master;
	file "/etc/bind/db.insec";
};

zone "1.168.192.in-addr.arpa" {
	type master;
	file "/etc/bind/db.1.168.192";
};
```

- specifies the zones for ".insec" and its reverse mapping, and the location of the corresponding zone files. 

Reload:

```bash
sudo service bind9 restart
```



### 3.2 Provide the output of dig(1) for a successful query.

On client,

Modify client /etc/resolv.conf:
```
nameserver 192.168.1.2
```

Dig:
```
vagrant@client:~$ dig ns1.insec

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> ns1.insec
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 33998
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: de3bb2a90ee53a3b0100000065cb0e20a730547d7d835cf7 (good)
;; QUESTION SECTION:
;ns1.insec.                     IN      A

;; ANSWER SECTION:
ns1.insec.              60      IN      A       192.168.1.2

;; Query time: 3 msec
;; SERVER: 192.168.1.2#53(192.168.1.2) (UDP)
;; WHEN: Tue Feb 13 06:37:20 UTC 2024
;; MSG SIZE  rcvd: 82
```



### 3.3 How would you add an IPv6 address entry to a zone file?

```
<hostname>	IN	AAAA	<IPv6-address>
```



## 4 Create a slave server for .insec

Configure *ns2* to work as a slave for .insec domain. Use a similar configuration as for the master, but don't create zone files.

On the master server, add an entry (A, PTR and NS -records) for your slave server. Don't forget to increment the serial number for the zone. Also allow zone transfers to your slave.

Reload configuration files in both machines and watch the logs. Verify that the zone files get transferred to the slave. Try to resolve machines in the .insec domain through both servers.



### 4.1 Demonstrate the successful zone file transfer.

```
dig ns1.insec @ns1
dig ns1.insec @ns2
```



### 4.2 Explain the changes you made.

On ns1,

Add to /etc/bind/db.insec:
```
@	IN	NS	ns2
```

Add to /etc/bind/1.168.192.in-addr.arpa
```
@	IN	NS	ns2
```

Modify /etc/bind/named.conf.local:
```
zone "insec" {
	type master;
	file "/etc/bind/db.insec";
	allow-transfer {192.168.1.3; };
	also-notify {192.168.1.3; };
};

zone "1.168.192.in-addr.arpa" {
	type master;
	file "/etc/bind/db.1.168.192";
	allow-transfer {192.168.1.3; };
	also-notify {192.168.1.3; };
};
```

On ns2,

/etc/bind/named.conf.options:
```
options {
    directory "/var/cache/bind";

    listen-on { 127.0.0.1; 192.168.1.3; };
    allow-query { 127.0.0.1; 192.168.1.0/24; };
};
```

/etc/bind/named.conf.local:
```
zone "insec" {
   type slave;
   file "/var/cache/bind/db.insec";
   masters { 192.168.1.2; };
};

zone "1.168.192.in-addr.arpa" {
   type slave;
   file "/var/cache/bind/db.1.168.192";
   masters { 192.168.1.2; };
};
```

Reload:
```bash
sudo service bind9 restart
```





### 4.3  Provide the output of *dig(1)* for a successful query from the slave server. Are there any differences to the queries from the master?

```
vagrant@ns2:/etc/bind$ dig ns1.insec @localhost

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> ns1.insec @localhost
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51092
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 035ba811d0e989fe0100000065cb1b7c2fee53983083bc90 (good)
;; QUESTION SECTION:
;ns1.insec.                     IN      A

;; ANSWER SECTION:
ns1.insec.              60      IN      A       192.168.1.2

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(localhost) (UDP)
;; WHEN: Tue Feb 13 07:34:20 UTC 2024
;; MSG SIZE  rcvd: 82
```

Not really.



## 5 Create a subdomain .not.insec.

Similar to above, create a subdomain .not.insec, use ns2 as a master and ns3 as a slave. Remember to add an entry for subdomain NS in the .not.insec zone files.

> N.B You are creating a subdomain of .insec, so a simple copy paste of 4 won't work. Check out bind9 delegation.

Reload configuration files in all three servers (watch the logs) and verify that the zone files get transferred to both slave servers. Try to resolve machines in .not.insec -domain from all three servers.



### 5.1 Explain the changes you made.

On ns1:
Add to /etc/bind/db.insec:

```
not.insec.	IN	NS	ns2.not.insec.
ns2.not.insec.	IN	A	192.168.1.3
```

On ns2,

Add to /etc/bind/db.not.insec:
```
\$TTL 60
@	IN	SOA	ns2.not.insec. hostmaster.insec. (
			2023021101      ; Serial 
			60							; Refresh 
			60							; Retry 
			604800					; Expire 
			60	)						; Minimum 
			
@	IN	NS	ns2
@	IN	NS	ns3
ns2 IN  A   192.168.1.3
ns3 IN  A   192.168.1.4
```

Add to /etc/bind/named.conf.local:

```
zone "not.insec" {
   type master;
   file "/etc/bind/db.not.insec";
   allow-transfer { 192.168.1.4; };
};
```

On ns3,
/etc/bind/named.conf.options:

```
options {
    directory "/var/cache/bind";

    listen-on { 127.0.0.1; 192.168.1.4; };
    allow-query { 127.0.0.1; 192.168.1.0/24; };
};
```

/etc/bind/named.conf.local:
```
zone "not.insec" {
   type slave;
   file "/var/cache/bind/db.not.insec";
   masters { 192.168.1.3; };
};
```

Reload:
```bash
sudo service bind9 restart
```





###  5.2 Provide the output of *dig(1)* for successful queries from all the three name servers.

```bash
vagrant@client:~$ sudo dig ns2.not.insec @ns1

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> ns2.not.insec @ns1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 42826
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: daaf9636442c5cb50100000065cb2290608a569fb889d018 (good)
;; QUESTION SECTION:
;ns2.not.insec.                 IN      A

;; ANSWER SECTION:
ns2.not.insec.          60      IN      A       192.168.1.3

;; Query time: 11 msec
;; SERVER: 192.168.1.2#53(ns1) (UDP)
;; WHEN: Tue Feb 13 08:04:32 UTC 2024
;; MSG SIZE  rcvd: 86

vagrant@client:~$ sudo dig ns2.not.insec @ns2

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> ns2.not.insec @ns2
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 57186
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 648035153f52706d0100000065cb2292e4f4ec5f9edd9fbe (good)
;; QUESTION SECTION:
;ns2.not.insec.                 IN      A

;; ANSWER SECTION:
ns2.not.insec.          60      IN      A       192.168.1.3

;; Query time: 3 msec
;; SERVER: 192.168.1.3#53(ns2) (UDP)
;; WHEN: Tue Feb 13 08:04:34 UTC 2024
;; MSG SIZE  rcvd: 86

vagrant@client:~$ sudo dig ns2.not.insec @ns3

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> ns2.not.insec @ns3
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 32646
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: a444badc469219c30100000065cb2341f38a5affe1ee45d0 (good)
;; QUESTION SECTION:
;ns2.not.insec.                 IN      A

;; ANSWER SECTION:
ns2.not.insec.          60      IN      A       192.168.1.3

;; Query time: 3 msec
;; SERVER: 192.168.1.4#53(ns3) (UDP)
;; WHEN: Tue Feb 13 08:07:29 UTC 2024
;; MSG SIZE  rcvd: 86
```





## 6 Implement transaction signatures



One of the shortcomings of DNS is that the zone transfers are not authenticated, which opens up an opportunity to alter the zone files during updates. Prevent this by enhancing the .not.insec -domain to implement transaction signatures.

Generate a secret key to be shared between masters and slaves with the command *tsig**-keygen(8)*. Use HMAC-SHA1 as the algorithm.

Create a shared key file with the following template:

```
key keyname {
algorithm hmac-sha1;
secret "generated key";
};

# server to use key with
server ip-addr {
keys { keyname; };
};
```



Fill in the generated key and server IP address, and make the key available to both the name servers of .not.insec. Include the key file in both the .not.insec name servers' *named.conf* files, and configure servers to only allow transfers signed with the key.

First try an unauthenticated transfer - and then proceed to verify that you can do authenticated zone transfers using the transaction signature.



### 6.1 Explain the changes you made. Show the successful and the unsuccessful zone transfer in the log.

On ns2,

Genrate a secret key:

```bash
tsig-keygen -a HMAC-SHA1 ns2.not.insec
```

Modify and add to /etc/bind/named.conf.local:
```
key ns2.not.insec.key {
	algorithm hmac-sha1;
	secret "****";
};

zone "not.insec" {
   type master;
   file "/etc/bind/db.not.insec";
   allow-transfer { key ns2.not.insec.key; };
};
```

On ns3,

Add to /etc/bind/named.conf.local:
```
key ns2.not.insec.key {
	algorithm hmac-sha1;
	secret "****";
};

server 192.168.1.3 {
  keys { ns2.not.insec.key; };
};
```

Reload:
```bash
sudo service bind9 restart
```

Log:
```bash
Feb 13 08:28:11 ubuntu-jammy named[11738]: zone not.insec/IN: notify from 192.168.1.3#35833: serial 2023021304
Feb 13 08:28:11 ubuntu-jammy named[11738]: zone not.insec/IN: Transfer started.
Feb 13 08:28:11 ubuntu-jammy named[11738]: transfer of 'not.insec/IN' from 192.168.1.3#53: connected using 192.168.1.3#53
Feb 13 08:28:11 ubuntu-jammy named[11738]: transfer of 'not.insec/IN' from 192.168.1.3#53: resetting
Feb 13 08:28:11 ubuntu-jammy named[11738]: transfer of 'not.insec/IN' from 192.168.1.3#53: connected using 192.168.1.3#53
Feb 13 08:28:11 ubuntu-jammy named[11738]: transfer of 'not.insec/IN' from 192.168.1.3#53: failed while receiving responses: REFUSED
Feb 13 08:28:11 ubuntu-jammy named[11738]: transfer of 'not.insec/IN' from 192.168.1.3#53: Transfer status: REFUSED
Feb 13 08:28:11 ubuntu-jammy named[11738]: transfer of 'not.insec/IN' from 192.168.1.3#53: Transfer completed: 0 messages, 0 records, 0 bytes, 0.001 secs (0 bytes/sec) (serial 2023021304)


vagrant@ns3:/etc/bind$ sudo tail -f /var/log/syslog
Feb 13 08:18:52 ubuntu-jammy named[11708]: client @0x7fe640021c48 192.168.1.3#33445: received notify for zone 'not.insec'
Feb 13 08:18:52 ubuntu-jammy named[11708]: zone not.insec/IN: notify from 192.168.1.3#33445: serial 2023021303
Feb 13 08:18:52 ubuntu-jammy named[11708]: zone not.insec/IN: Transfer started.
Feb 13 08:18:52 ubuntu-jammy named[11708]: transfer of 'not.insec/IN' from 192.168.1.3#53: connected using 192.168.1.3#53 TSIG ns2.not.insec.key
Feb 13 08:18:52 ubuntu-jammy named[11708]: zone not.insec/IN: transferred serial 2023021303: TSIG 'ns2.not.insec.key'
Feb 13 08:18:52 ubuntu-jammy named[11708]: transfer of 'not.insec/IN' from 192.168.1.3#53: Transfer status: success
Feb 13 08:18:52 ubuntu-jammy named[11708]: transfer of 'not.insec/IN' from 192.168.1.3#53: Transfer completed: 1 messages, 6 records, 258 bytes, 0.003 secs (86000 bytes/sec) (serial 2023021303)
Feb 13 08:18:52 ubuntu-jammy named[11708]: zone not.insec/IN: sending notifies (serial 2023021303)
Feb 13 08:25:58 ubuntu-jammy named[11708]: client @0x7fe640021c48 192.168.1.3#44968: received notify for zone 'not.insec'
Feb 13 08:25:58 ubuntu-jammy named[11708]: zone not.insec/IN: notify from 192.168.1.3#44968: zone is up to date
```







### 6.2 TSIG is one way to implement transaction signatures. DNSSEC describes another, SIG(0). Explain the differences.

- TSIG
  - a way to implement transaction signatures in DNS
  - uses a shared secret key to sign the messages exchanged between name servers
- SIG
  - uses a digital signature
  - uses public-key to sign the zone data





## 7 Pi-hole DNS sinkhole

Install Pi-hole on ns1 and configure the client to use it as their DNS. Perform a dig(1) query to a non-blacklisted domain such as google.com. Then blacklist that domain on the Pi-hole and repeat the query. (The result should not be same for both runs.)

```bashs
pihole -b google.com
pihole -b -l google.coms
```

[Overview of Pi-hole - Pi-hole documentation](https://docs.pi-hole.net/)



### 7.1 Based on the dig-queries, how does Pi-hole block domains on a DNS level?

By intercepting the DNS queries made by the client and matching the domain name being queried with the domains in its blacklist. If the domain is found in the blacklist, Pi-hole returns an IP address that leads to nowhere, effectively blocking the client's access to the domain.



### 7.2 How could you use Pi-hole in combination with your own DNS server, such as your caching-only nameserver?

By configuring the caching-only nameserver to forward the DNS queries to Pi-hole. Then Pi-hole can block unwanted domains.