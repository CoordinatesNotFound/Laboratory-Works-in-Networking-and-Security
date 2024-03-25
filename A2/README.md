# A2: Email Server



## 0 Introduction



> Additional Reading:
>
> - postconf(5) - Postfix Configuration Parameters
> - procmailrc(5) - Flags for procmail recipes
> - [GTUBE](https://spamassassin.apache.org/gtube/) - Testing spam filters
> - [spamd ](https://spamassassin.apache.org/full/3.4.x/doc/spamd.html)- Spamassassin daemon doc



### 0.1 Motivation

Setting up email servers isn’t something only big corporations like Google and Microsoft can do. In fact, setting up an email server on your virtual machines is relatively easy. This familiarizes you with the issues involved in running an email service, such as “How to deal with spam?” You will also learn about the structure of an email message, like the HTTP request from the previous exercise. You can see the mail process architecture between sender and receiver.

In an email delivery architecture, the following acronyms are used:

UA = User Agent, MSA = Mail Submission Agent, MTA = Mail Transfer Agent, MDA = Mail Delivery Agent, AA = Access Agent

- UA-to-MSA or -MTA as a message is injected into the mail system
- MSA-to-MTA as the message starts its delivery journey
- MTA- or MSA-to-antivirus or -antispam scanning programs 
- MTA-to-MTA as a message is forwarded from one site to another 
- MTA-to-MDA as a message is delivered to the local message store



### 0.2 Description of the exercise

In this exercise you will learn how to setup an email server with filtering rules and spam detection. Consider that from now on you'll have to do extensive self-research to be able to successfully complete the assignments.



## 1 Preparation

During this assignment you will need two hosts (**lab1** and **lab2**). Configure them in the same network, such that they can communicate to each other for mail delivery.



### 1.1 Add the IPv4 addresses and aliases of lab1 and lab2 on both computers to the */etc/hosts* file.

```
sudo echo "192.168.1.3 lab2" | sudo tee -a /etc/hosts
sudo echo "192.168.1.2 lab1" | sudo tee -a /etc/hosts
```



## 2 Installing software and Configuring postfix and exim4 

As a first step, install all the software that will be used in the assignment. Verify that the following packages are installed:

- lab1: postfix, procmail, spamassassin
- lab2: exim4

Postfix is the MTA used on lab1 for delivering the mail. Exim4 is the MTA used on lab2. Procmail is used as the MDA on lab1. Spamassassin, as the name suggests, is a tool used for spam detection.

Installing mailutils on lab1 can help with handling incoming mail. Then, you should configure postfix to deliver mail from lab2 to lab1.

Edit main configuration file for postfix (main.cf, postconf(5)) on lab1. You must change, at least, the following fields:

●   myhostname (from /etc/hosts)

●   mydestination

●   mynetworks (localhost and virtual machines IP block)

Disable ETRN and VRFY commands. Remember to reload postfix service /etc/init.d/postfix every time you edit main.cf.



### 2.1  Configure the postfix configuration file *main.cf* to fill the requirements above.

Modify main.cf:

```
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = lab1
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $myhostname, lab1, localhost.localdomain, localhost
relayhost =
mynetworks = 127.0.0.0/8 192.168.1.0/24
mailbox_command = procmail -a "$EXTENSION"
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

disable_vrfy_command = yes
fast_flush_domains =

```

Reload:
```bash
sudo postfix reload
```





### 2.2 What is purpose of the *main.cf* setting "mydestination"?

The `mydestination` parameter in Postfix specifies the list of domains that are delivered via the local MDA. These are the domains for which your mail server considers itself the final destination. In other words, it defines the list of domains that should be accepted as local, and the mail will be delivered locally. (Otherwise, it will forward it to other MTAs)



### 2.3 Why is it a really bad idea to set mynetworks broader than necessary (e.g. to 0.0.0.0/0)?

Setting `mynetworks` too broadly (e.g., to `0.0.0.0/0`) allows any host on the internet to connect to your mail server without restriction. This can lead to unauthorized use, spam relay, and potential security vulnerabilities. It's crucial to limit `mynetworks` to only the necessary IP ranges to enhance security.



### 2.4  What is the idea behind the ETRN and VRFY verbs? How can a malicious party misuse the commands?

Idea:

- ETRN (Extended Turn): It can be used by remote email servers to request the immediate delivery of queued email. For example, when a remote server comes back from offline status to online status, it may request the local server to send the queued messages
- VRFY (Verify): It is used to verify the existence of an email address on a server. 

Misuse:

- ETRN: Malicious parties might misuse ETRN to flood the server with requests, leading to a denial-of-service situation.
- VRFY: Attackers can use VRFY to obtain a list of valid email addresses for spamming or other malicious activities.



### 2.5  Configure exim4 on **lab2** to handle local emails and send all the rest to **lab1**. After you have configured postfix and exim4 you should be able to send mail from **lab2** to **lab1**, but not vice versa. Use the standard debian package reconfiguration tool dpkg-reconfigure(8) to configure exim4.

Modify /etc/exim4/update-exim4.conf.conf:
```
dc_eximconfig_configtype='satellite'
dc_other_hostnames='lab2'
dc_local_interfaces=''
dc_readhost=''
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost='lab1'
CFILEMODE='644'
dc_use_split_config='false'
dc_hide_mailname='true'
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
```

Update it:
```
sudo update-exim4.conf
```





## 3  Sending email

Send a message from **lab2** to `<user>@lab1` using *mail(1)*. Replace the <user> with your username. Read the message on **lab1**. See also email message headers. See incoming message information from *var/log/mail.log* using *tail(1)*.

On lab2:

```
echo "hello world" | mail -s "test" -v vagrant@lab1
```

On lab1:
```
sudo tail /var/log/mail.log
```





### 3.1  Explain shortly the incoming mail log messages

```
Feb  3 13:28:26 lab1 postfix/smtpd[5998]: connect from lab2[192.168.1.3]
Feb  3 13:28:26 lab1 postfix/smtpd[5998]: ABF203FEF6: client=lab2[192.168.1.3]
Feb  3 13:28:26 lab1 postfix/cleanup[6002]: ABF203FEF6: message-id=<E1rWFy7-0001en-HQ@lab2>
Feb  3 13:28:26 lab1 postfix/qmgr[5966]: ABF203FEF6: from=<vagrant@lab2>, size=551, nrcpt=1 (queue active)
Feb  3 13:28:26 lab1 postfix/smtpd[5998]: disconnect from lab2[192.168.1.3] ehlo=1 mail=1 rcpt=1 bdat=1 quit=1 commands=5
Feb  3 13:28:28 lab1 postfix/local[6003]: A20E73FEF4: to=<vagrant@lab1>, relay=local, delay=1.5, delays=0.01/0.01/0/1.5, dsn=2.0.0, status=sent (delivered to command: procmail -a "$EXTENSION")
Feb  3 13:28:28 lab1 postfix/qmgr[5966]: A20E73FEF4: removed
Feb  3 13:28:34 lab1 postfix/local[6007]: ABF203FEF6: to=<vagrant@lab1>, relay=local, delay=8, delays=0/0.01/0/8, dsn=2.0.0, status=sent (delivered to command: procmail -a "$EXTENSION")
Feb  3 13:28:34 lab1 postfix/qmgr[5966]: ABF203FEF6: removed
```

- Line 1: a connection was made to the email server from the IP address 192.168.1.3, which is associated with the hostname lab2.
- Line 2-5: The email with ID ABF203FEF6 originated from user vagrant on lab2 and was addressed to lab1
- Line 6,8: Postfix successfully delivered the email to the local user vagrant's mailbox and processed it using procmail..
- Line 7,9: After successful delivery, the email was removed from the mail queue.





### 3.2  Explain shortly the email headers. At what point is each header added?

```
"/var/mail/vagrant": 2 messages 2 new
>N   1 vagrant@lab2       Sat Feb  3 13:28  22/617   test
 N   2 vagrant@lab2       Sat Feb  3 13:28  22/617   test
?
Return-Path: <vagrant@lab2>
X-Original-To: vagrant@lab1
Delivered-To: vagrant@lab1
Received: from lab2 (lab2 [192.168.1.3])
        by lab1 (Postfix) with ESMTP id A20E73FEF4
        for <vagrant@lab1>; Sat,  3 Feb 2024 13:28:26 +0000 (UTC)
Received: from vagrant by lab2 with local (Exim 4.95)
        (envelope-from <vagrant@lab2>)
        id 1rWG4I-0001f7-IA
        for vagrant@lab1;
        Sat, 03 Feb 2024 13:28:26 +0000
To: vagrant@lab1
Subject: test
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 8bit
Message-Id: <E1rWG4I-0001f7-IA@lab2>
From: vagrant@lab2
Date: Sat, 03 Feb 2024 13:28:26 +0000

hello world

?
```

The headers contain information about the message, such as the sender, recipient, subject, date, and other details. The body contains the actual content of the message.

Email headers are added to a message at different points in the email delivery process. Here are a few examples:

- The From header is added when the email is composed by the sender.
- The To header is added when the email is addressed to the recipient.
- The Subject header is added when the email is given a subject.
- The Received header is added by each mail server that handles the message. This header contains information about the server and the time it received the message.
- The Message-ID header is added when the message is first composed, it's unique identifier for the message.
- The Date header is added when the email is sent.
- Some headers are added by the client software or the email server software, such as the MIME-Version header, which specifies the version of the MIME standard used in the message.
- The Content-Type header specifies the type of content in the message, such as text, image, or audio.
- The Content-Transfer-Encoding header specifies the encoding used to encode the message body.
- The Return-Path header specifies the address to which undeliverable messages should be sent.





## 4 Configuring procmail and spamassassin

Next, you will configure procmail to deliver any incoming mail for spam filtering to spamassassin, and then filter to folders with self-configured rules.

Procmail is configured by writing instruction sets caller recipes to a configuration file procmailrc(5). Edit (create if necessary) */etc/procmailrc* and begin by piping your arriving emails into spamassassin with the following recipe:

```
:0fw
| /usr/bin/spamassassin
```

In postfix *main.cf*, you have to enable procmail with [mailbox_command](http://www.postfix.org/postconf.5.html#mailbox_command) line:

`/usr/bin/procmail -a "$USER"`

Remember to reload postfix configuration after editing it.

You may need to start the spamassassin daemon after enabling it in the configuration file /etc/default/spamassassin.

Send an email message from **lab2** to `<user>@lab1`. Read the message on **lab1**. See email headers. If you do not see spamassassin headers there is something wrong, go back to previous step and see */var/log/mail.log*.

Write additional procmail recipes to:

●   Automatically filter spam messages to a different folder.

●   Add a filter for your user to automatically save a copy of a message with header [cs-e4160] in the subject field to a different folder.

●   Forward a copy of the message with the same [cs-e4160] header to `testuser1@lab1` (create user if necessary).

> *Hint:* You can use file *.procmailrc* in user's home directory for user-specific rules.



Create /etc/procmailrc:
```
:0fw
| /usr/bin/spamassassin
```

Modify /etc/postfix/main.cf
```
mailbox_command = /usr/bin/procmail -a "$USER"
```

Refresh:
```bash
sudo postfix reload
```

Enable spamassassin in  /etc/default/spamassassin:
```
ENABLED = 1
```

Start/Restart the service:
```bash
sudo service spamassassin restart
```

Check header:
```
Return-Path: <vagrant@lab2>
X-Spam-Checker-Version: SpamAssassin 3.4.6 (2021-04-09) on lab1
X-Spam-Level:
X-Spam-Status: No, score=-0.9 required=5.0 tests=ALL_TRUSTED,TO_MALFORMED,
        TVD_SPACE_RATIO autolearn=no autolearn_force=no version=3.4.6
X-Original-To: vagrant@lab1
Delivered-To: vagrant@lab1
Received: from lab2 (lab2 [192.168.1.3])
        by lab1 (Postfix) with ESMTP id 266C03FEF4
        for <vagrant@lab1>; Sat,  3 Feb 2024 13:52:32 +0000 (UTC)
Received: from vagrant by lab2 with local (Exim 4.95)
        (envelope-from <vagrant@lab2>)
        id 1rWGRc-0001fN-1k
        for vagrant@lab1;
        Sat, 03 Feb 2024 13:52:32 +0000
To: vagrant@lab1
Subject: spamassassin
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 8bit
Message-Id: <E1rWGRc-0001fN-1k@lab2>
From: vagrant@lab2
Date: Sat, 03 Feb 2024 13:52:32 +0000

hello world

?
```

Add additional rules:
```
:0
* ^Subject:.*\[cs-e4160\]
cs-e4160/

:0c
* ^Subject:.*\[cs-e4160\]
! testuser1@lab1

:0
* ^X-Spam-Status: Yes
spam/
```





### 4.1 How can you automatically filter spam messages to a different folder using procmail? Demonstrate by sending a message that gets flagged as spam.

Send spam mail:

> https://opensource.apple.com/source/SpamAssassin/SpamAssassin-124.1/SpamAssassin/sample-spam.txt.auto.html

```bash
mail -s "test spam mail (GTUBE)" -v vagrant@lab1

This is the GTUBE, the
	Generic
	Test for
	Unsolicited
	Bulk
	Email

If your spam filter supports it, the GTUBE provides a test by which you
can verify that the filter is installed correctly and is detecting incoming
spam. You can send yourself a test mail containing the following string of
characters (in upper case and with no white spaces and line breaks):

XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X

You should send this test mail from an account outside of your network.
```

Received on lab1:
```
Content analysis details:   (999.1 points, 5.0 required)

 pts rule name              description
---- ---------------------- --------------------------------------------------
-1.0 ALL_TRUSTED            Passed through trusted hosts only via SMTP
1000 GTUBE                  BODY: Generic Test for Unsolicited Bulk Email
 0.1 TO_MALFORMED           To: has a malformed address



------------=_65BE5261.DAFF93EB
Content-Type: message/rfc822; x-spam-type=original
Content-Description: original message before SpamAssassin
Content-Disposition: inline
Content-Transfer-Encoding: 8bit

Return-Path: <vagrant@lab2>
X-Original-To: vagrant@lab1
Delivered-To: vagrant@lab1
Received: from lab2 (lab2 [192.168.1.3])
        by lab1 (Postfix) with ESMTP id ED0083FF07
        for <vagrant@lab1>; Sat,  3 Feb 2024 14:49:03 +0000 (UTC)
Received: from vagrant by lab2 with local (Exim 4.95)
        (envelope-from <vagrant@lab2>)
        id 1rWHKJ-0001gv-SH
        for vagrant@lab1;
        Sat, 03 Feb 2024 14:49:03 +0000
To: vagrant@lab1
Subject: Test spam mail (GTUBE)
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 8bit
Message-Id: <E1rWHKJ-0001gv-SH@lab2>
From: vagrant@lab2
Date: Sat, 03 Feb 2024 14:49:03 +0000

This is the GTUBE, the
        Generic
        Test for
        Unsolicited
        Bulk
        Email

If your spam filter supports it, the GTUBE provides a test by which you
can verify that the filter is installed correctly and is detecting incoming
spam. You can send yourself a test mail containing the following string of
characters (in upper case and with no white spaces and line breaks):

XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X

You should send this test mail from an account outside of your network.


------------=_65BE5261.DAFF93EB--
```







### 4.2 Demonstrate the filter rules created for messages with [cs-e4160] in the subject field by sending a message from **lab2** to `<user>@lab1` using the header.

Send a message:
```bash
echo "cs" | mail -s "[cs-e4160]" -v vagrant@lab1
```

Received on lab1:
```
Return-Path: <vagrant@lab2>
X-Spam-Checker-Version: SpamAssassin 3.4.6 (2021-04-09) on lab1
X-Spam-Level:
X-Spam-Status: No, score=-0.9 required=5.0 tests=ALL_TRUSTED,TO_MALFORMED,
        TVD_SPACE_RATIO autolearn=no autolearn_force=no version=3.4.6
X-Original-To: vagrant@lab1
Delivered-To: vagrant@lab1
Received: from lab2 (lab2 [192.168.1.3])
        by lab1 (Postfix) with ESMTP id 5F9F23FF07
        for <vagrant@lab1>; Sat,  3 Feb 2024 14:30:34 +0000 (UTC)
Received: from vagrant by lab2 with local (Exim 4.95)
        (envelope-from <vagrant@lab2>)
        id 1rWH2Q-0001gL-9Q
        for vagrant@lab1;
        Sat, 03 Feb 2024 14:30:34 +0000
To: vagrant@lab1
Subject: [cs-e4160]
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 8bit
Message-Id: <E1rWH2Q-0001gL-9Q@lab2>
From: vagrant@lab2
Date: Sat, 03 Feb 2024 14:30:34 +0000

cs

```





### 4.3  Explain briefly the additional email headers (compared to step 3.2).

- X-Spam-Checker-Version is the version of the spam filter used.
- X-Spam-Status is the result of the spam filter. It contains the score, the required score, the tests used, and the version of the spam filter.
- X-Original-To is the original recipient of the email before procmail handles.





## 5 E-mail servers and DNS

Configuring a DNS server is the task for the B-path next week. Information about mail servers is also stored in the DNS system. To get a surface level understanding, study the topic from the internet.



### 5.1  What information is stored in MX records in the DNS system?

MX records information about mail servers responsible for accepting email messages for a particular domain. e.g. the hostname and priority of a mail server. The priority is used to determine the order in which mail servers should be contacted if multiple servers are listed for a domain. 

#### 





### 5.2 Explain briefly two ways to make redundant email servers using multiple email servers and the DNS system. Name at least two reasons why you would have multiple email servers for a single domain?

Ways:

1. have multiple MX records for a domain, each with a different priority. This allows for failover in case the primary mail server is unavailable. 
2. by using a load balancer. The load balancer will distribute the incoming email traffic among multiple email servers.

Reasons

- Redundancy: By having multiple servers, you can ensure that email service is not interrupted in case one of the servers goes down.
- Scalability: As the number of email users or the volume of email traffic increases, it may be necessary to distribute the load among multiple servers in order to maintain performance and avoid bottlenecks.
- Security: By having multiple servers, you can implement different security measures to mitigate different types of threats or vulnerabilities.
