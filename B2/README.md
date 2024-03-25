# B2: Web Server



## 0 Introduction



> Additional reading:
>
> - [Apache module index](https://httpd.apache.org/docs/current/mod/) 
> - [NGINX Documentation](https://docs.nginx.com/)
> - [Index | Node.js v21.6.1 Documentation](https://nodejs.org/docs/latest/api/)



### 0.1 Motivation

Serving a web page requires a running server, listening for incoming HTTP requests, and answering them by returning the requested page. Taking last exercise’s bogus server further, this time you will serve an actual web page to a browser requesting it. Websites can consist of multiple servers around the world, to load balance, to keep latency low, or to keep important information on more secure servers. To simulate this, you will set up a reverse proxy that will forward different requests to different servers.



### 0.2 Description of the exercise

In this exercise, you will introduce yourself to some basic features of Apache web server and its plugins. In addition to that you will set up a Node.js server for serving a webpage, and configure an nginx server as a reverse proxy for the servers. Take into account that from now on you'll have to do extensive self-research to be able to successfully complete the assignments. You will need three virtual machines to complete this assignment. The final web server network configuration will look like the image below.



## 1 Apache2

Apache2 allows for quick and easy configuration of a web server on Linux machines, while being extensible with many easy to use modules. It is a quick first step, if you need to host a website on your own computer for example, but is also usable in a production environment.

Install Apache2 on **lab2**. The modules used later for serving user directory contents, rewriting URLs and setting up SSL should come with Apache2 by default. Set up SSH port forwarding for HTTP and HTTPS so that you can test the server on your local machine (localhost) with your favourite web browser. Note that VirtualBox port forwarding is not the way to do this! Instead, look into the ssh(1) manual page and use an ssh command to link the ports on the virtual machines to ports on the host.





### 1.1 Serve a default web page using Apache2

In lab2, Install Apache2:

```bash
sudo apt install apache2
```

Then it serves a default web page

To test the result:

```
curl http://localhost
```





### 1.2 Show that the web page can be loaded on local browser using SSH port forwarding.

Port Forwarding:

```bash
ssh -L 8080:localhost:80 -N vagrant@localhost -p 2200
```



## 2 Serve a web page using Node.js

Node is a cross platform browser-free JavaScript runtime environment, which can also be used as a HTTP server, when configured with the appropriate modules. The purpose of this assignment is to familiarize yourself with the increasingly popular and simple method of serving web applications using Node.js. Although javascript skills are not really needed in this assignment, we strongly recommend that you take a deeper look at javascript and also node.js



### 2.1 Provide a working web page with the text "Hello World!"

Install node and npm:
```bash
sudo apt install node
sudo apt install npm
```

Create a file `helloworld.js` on lab3:

```javascript
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end('<html><body><h1>Hello World!</h1></body></html>');
});

const PORT = 8080;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
```

Start listening:
```bash
node helloworld.js
```

To make it a system service:
```bash
sudo nano /etc/systemd/system/helloworld.service
```

With:
```
[Unit]
Description=Nodejs server service
[Service]
ExecStart=/bin/bash -c "cd /home/vagrant && node helloworld.js"
Restart=always
[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl enable server --now
```





### 2.2  Explain the contents of the helloworld.js javascript file.

```javascript
// Import HTTP module.
const http = require('http');

// Define an HTTP server that listens for requests
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' }); // Set the response Header
  res.end('<html><body><h1>Hello World!</h1></body></html>'); // Send the response body
});

// Start listening on port 8080
const PORT = 8080;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
```



### 2.3 What does it mean that Node.js is event driven? What are the advantages in such an approach?

Node.js is event-driven, which means it uses an event loop to handle asynchronous operations. It set up a series of event handlers which can process multiple events simultaneously.

 The advantages include:

- Scalability: It can handle a large number of connections simultaneously without the need for threading.
- Efficiency: Non-blocking I/O operations allow for more efficient handling of concurrent requests.
- Responsive: It responds to events immediately, making it suitable for real-time applications like chat applications or online gaming.





## 3 Configuring SSL for Apache2

This next part introduces you to SSL certificates by configuring your Apache server with one that you create.

On lab2, use the Apache ssl module to enable https connections to the server. Create a 2048-bit RSA-key for the Apache2 server. Then create a certificate that matches to the key. The suggested method for achieving these two steps is using openssl. Configure Apache2 to use this certificate for HTTPS traffic. Set up again SSH port forwarding for the HTTPS port to test the secure connection using your local browser (if it is not active already).

> Note: Taking a shortcut with CA.pl is not accepted, you need to understand the process! Only a few commands are needed, though. Both the key and certificate can be created simultaneously using a single shell command.



### 3.1 Provide and explain your solution.

Install the ssl for apache2 and restart apache2
```bash
sudo a2enmod ssl
sudo systemctl restart apache2
```

Generate the key and certificate:
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/lab2.key -out /etc/ssl/certs/lab2.crt
```

Check the ssl configuration:
```
sudo nano /etc/apache2/sites-available/default-ssl.conf
```

Make modification:
```
SSLCertificateFile /etc/ssl/certs/lab2.crt
SSLCertificateKeyFile /etc/ssl/private/lab2.key
```

Enable default-ssl:
```bash
sudo a2ensite default-ssl
```

Restart apache2:
```bash
sudo systemctl apache2 restart
```

Back to local machine and conduct port forwarding:
```bash
ssh -L 8443:localhost:443 vagrant@localhost -p 2200 -N
```



### 3.2 What information can a certificate include? What is necessary for it to work in the context of a web server?

A certificate is a digital document that is used to authenticate the identity of a website or other entity over the internet. A certificate includes information such as **the domain name of the website, the name and address of the organization that owns the website, and the name of the certificate authority that issued the certificate**. It also includes **a public key and a digital signature that can be used to verify the authenticity of the certificate**. For a certificate to work in the context of a web server, it must **be issued by a trusted certificate authority** and it must be installed on the server and properly configured so that it is used for HTTPS connections.





### 3.3 What do PKI and requesting a certificate mean?

PKI (Public Key Infrastructure) is **a set of technologies and policies that are used to secure digital communications and transactions by creating a trust infrastructure**. A key component of PKI is the use of digital certificates, which are used to authenticate the identity of a website or other entity over the internet. Requesting a certificate means **asking a certificate authority (CA) to issue a digital certificate**, which is a digital document that contains information about the identity of a website or other entity, along with a public key. The certificate is then used to establish trust between the server and the clients that connect to it. The process of requesting a certificate includes providing the necessary information to the CA, such as the domain name of the website and the name and address of the organization that owns the website, and then verifying that the information is correct and that the organization is authorized to use the domain name.

## 

## 4 Enforcing HTTPS

Next, you will enforce the use of an SSL encrypted connection for one page on your server, while still allowing http on another. You will also learn to serve a directory from the user's home directory.

On lab2, create a “public_html” directory and subdirectory called "secure_secrets" in your user’s home directory. Use the Apache userdir module to serve public_html from users' home directories.

Enforce access to the secure_secrets subdirectory with HTTPS by using rewrite module and .htaccess file, so that Apache2 forwards "http://localhost/~user/secure_secrets" to "https://localhost/~user/secure_secrets". Please note that this is a bit more complicated to test with the ssh forwarding, so you can test it locally with lynx or netcat at the virtual machine. If your demo requires, you may hard-code your port numbers to the forwarding rules.



### 4.1 Provide and explain your solution.

Create the directories:
```bash
mkdir ~/public_html
mkdir ~/public_html/secure_secrets
```

Check the userdir module:
```bash
sudo nano /etc/apache2/mods-available/userdir.conf
```

Make sure:
```bash
UserDir public_html
UserDir disabled root
```

Enable userdir module:
```bash
chmod 755 ~
sudo a2enmod userdir
sudo a2enmod rewrite
sudo systemctl restart apache2
```

Create .htaccess:
```bash
nano ~/public_html/secure_secrets/.htaccess
```

With:
```
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

Test:
```bash
curl -v http://localhost/~vagrant/secure_secrets
lynx http://localhost/~vagrant/secure_secrets
```



### 4.2  What is HSTS?

HSTS (HTTP Strict Transport Security) is a security mechanism that is used to help protect websites against man-in-the-middle (MITM) attacks. It works by telling web browsers that they should only communicate with a website over HTTPS, even if the user types "http://" in the URL bar or clicks on a link that starts with "http://". This helps to prevent attackers from intercepting and modifying the communication between the browser and the website, and can help to protect users from phishing and other types of attacks.





### 4.3 When to use .htaccess? In contrast, when not to use it?

**.htaccess is a configuration file that is used to control how Apache web server behaves for a specific directory and its subdirectories**. The .htaccess file is typically used to configure the server for specific functionality, such as setting up redirects, password protection, and custom error pages. It can also be used to configure the server for specific functionality, such as setting up redirects, password protection, and custom error pages.

It's typically used when you don't have access to the main apache configuration or when you have a shared hosting environment.

When not to use it:

- When you have access to the main apache configuration and can make changes there instead.
- When you are dealing with a high traffic website, as .htaccess files may slow down the server and cause performance issues.
- When you have a lot of rules and configurations, it can become hard to manage and test the rules in a .htaccess file.
- When you are using a different web server other than Apache.
- It's important to note that using .htaccess is not always the best option, and it's best to use it in the proper context.The contents of the nginx configuration file are used to configure the behavior of the nginx server. The example above, it's defining a "server" block. Within this block, the first line is the "listen" directive, which tells nginx to listen on port 80 for incoming requests. The second line is the "server_name" directive, which tells nginx to respond to requests for the hostname "lab1".

Then we have two "location" blocks, one for /apache and one for /node, this blocks define the behavior of the server when a request is made to a specific path. The "proxy_pass" directive in each block tells nginx to forward requests to the specified URL.





## 5 Install nginx as a reverse proxy

Nginx is a third commonly used way of serving webpages, and also allows functioning as a proxy. Next, you are going to serve both Apache2 and Node.js hello world from lab1 using *nginx* as a reverse proxy.

Install *nginx* on lab1 and configure it to act as a gateway to both Apache2 at lab2 and Node.js at lab3 the following way:

HTTP requests to *http://lab1/apache* are directed to Apache2 server listening on lab2:80 and requests to *http://lab1/node* to Node.js server on lab3:8080.



### 5.1  Provide a working solution serving both web applications from nginx.

```nginx
server {
    listen 80;

    server_name lab1;

    location /apache {
     		rewrite /apache(/|$)(.*) /$2  break;
        proxy_pass http://lab2:80;
        proxy_set_header Host $host;
    }

    location /node {
        proxy_pass http://lab3:8080;
        proxy_set_header Host $host;
    }

}
```



### 5.2 Explain the contents of the nginx configuration file.

The contents of the nginx configuration file are used to configure the behavior of the nginx server. The example above, it's defining a "server" block. Within this block, the first line is the "listen" directive, which tells nginx to listen on port 80 for incoming requests. The second line is the "server_name" directive, which tells nginx to respond to requests for the hostname "lab1".

Then we have two "location" blocks, one for /apache and one for /node, this blocks define the behavior of the server when a request is made to a specific path. The "proxy_pass" directive in each block tells nginx to forward requests to the specified URL.



### 5.3 What is commonly the primary purpose of an nginx server and why?

The primary purpose of an nginx server is to act as a **reverse proxy.** It's commonly used as a reverse proxy to handle incoming HTTP and HTTPS requests and forward them to the appropriate backend server, in this case Apache2 and Node.js. This allows nginx to handle tasks such as load balancing, SSL/TLS termination, caching, and serving static files, so that the backend servers can focus on handling the application-specific tasks. Additionally, nginx is highly configurable and can be used for a variety of purposes, such as a reverse proxy, web server, load balancer, and more. It is also known for its high performance and low resource usage, making it a popular choice for high traffic websites and web applications.





## 6 Test Damn Vulnerable Web Application

For security purposes, security professionals and penetration testers set up a Damn Vulnerable Web Application to practice some of the most common vulnerabilities. To achieve this goal, you can download the file in https://github.com/digininja/DVWA/ and install it on lab2.  You can delete the default Apache index.html and install the web application to be served as the default webpage. Finally, install Nikto tool which is an open-source web server scanner on lab 1 and scan your vulnerable web application.



On lab2, prepare DVWA:

```bash
git clone https://github.com/digininja/DVWA.git

mv DVWA /var/www/html/

cd DVWA

cp config/config.inc.php.dist config/config.inc.php

sudo apt install -y apache2 mariadb-server mariadb-client php php-mysqli php-gd libapache2-mod-php
```



### 6.1 Using Nmap, enumerate the lab2, and detect the os version, php version, apache version and open ports

Command:

```bash
sudo nmap -A -p- -T5 lab2
```

Result:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2024-02-03 02:21 UTC
Nmap scan report for lab2 (192.168.1.3)
Host is up (0.0011s latency).
Not shown: 65532 closed ports
PORT    STATE SERVICE VERSION
22/tcp  open  ssh     OpenSSH 8.9p1 Ubuntu 3ubuntu0.6 (Ubuntu Linux; protocol 2.0)
80/tcp  open  http    Apache httpd 2.4.52 ((Ubuntu))
|_http-server-header: Apache/2.4.52 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
443/tcp open  ssl/ssl Apache httpd (SSL-only mode)
|_http-server-header: Apache/2.4.52 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
| ssl-cert: Subject: commonName=lab2/organizationName=aalto/stateOrProvinceName=Helsinki/countryName=FI
| Not valid before: 2024-02-02T23:13:37
|_Not valid after:  2025-02-01T23:13:37
| tls-alpn:
|_  http/1.1
MAC Address: 08:00:27:7A:47:2F (Oracle VirtualBox virtual NIC)
Aggressive OS guesses: Linux 2.6.32 (96%), Linux 3.2 - 4.9 (96%), Linux 2.6.32 - 3.10 (96%), Linux 3.4 - 3.10 (95%), Linux 3.1 (95%), Linux 3.2 (95%), AXIS 210A or 211 Network Camera (Linux 2.6.17) (94%), Linux 2.6.32 - 2.6.35 (94%), Linux 2.6.32 - 3.5 (94%), Linux 2.6.32 - 3.13 (93%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 1 hop
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

TRACEROUTE
HOP RTT     ADDRESS
1   1.07 ms lab2 (192.168.1.3)

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 19.58 seconds
```





### 6.2 Using Nikto, to detect vulnerabilities on lab2

Command:

```bash
nikto -h http://lab2
```

Result:

```
- Nikto v2.1.5
---------------------------------------------------------------------------
+ Target IP:          192.168.1.3
+ Target Hostname:    lab2
+ Target Port:        80
+ Start Time:         2024-02-03 02:24:46 (GMT0)
---------------------------------------------------------------------------
+ Server: Apache/2.4.52 (Ubuntu)
+ Server leaks inodes via ETags, header found with file /, fields: 0x29af 0x6106d670f9722
+ The anti-clickjacking X-Frame-Options header is not present.
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ Allowed HTTP Methods: HEAD, GET, POST, OPTIONS
+ 6544 items checked: 0 error(s) and 3 item(s) reported on remote host
+ End Time:           2024-02-03 02:25:04 (GMT0) (18 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

