# B4: Network Filesystems



## 0 Introduction

> Additional reading:
>
> - [Samba](http://www.samba.org/) - Windows interoperability suite of programs for Linux and Unix
> - NFS - Network File System - [Sourceforge](http://nfs.sourceforge.net/), [Wikipedia](http://en.wikipedia.org/wiki/Network_File_System_(protocol))
> - [sshfs](http://fuse.sourceforge.net/sshfs.html) - SSH Filesystem (and [FUSE](http://fuse.sourceforge.net/))
> - [WebDAV](http://www.webdav.org/) - Web-based Distributed Authoring and Versioning [1]





### 0.1 Motivation 

Network filesystems create a way to access files on another computer as if they are located on your computer. A basic approach to accessing remote files would be to download them, edit them and then upload the edited versions to the server. Mounting the files as a directory on your computer makes it easier to manage and use the files and synchronize changes between your computer and the remote server. Data integrity loss due to device failure can be very problematic. To prevent such data loss, redundancy and integrity mechanisms can be integrated into file systems.



### 0.2 Description of the exercise

In this exercise you will setup various network filesystems and raid 5. You have to compare network filesystems shortly using internet (or book) sources and your own experiments. Please use NFSv3 for this exercise. Doing the demo with NFSv4 is also acceptable, as long as you can answer the questions.



## 1 Preparation

You'll need two virtual machines for this exercise. Add aliases (*lab1* and *lab2*) for the addresses to */etc/hosts*.

Create two new users (e.g. "testuser1" and "testuser2") with adduser to both the computers. Ensure that users have the same UID on both computers (eg. testuser1 UID is 1001 on **lab1** and **lab2**, testuser2 is 1002). The easiest way is to create both users in the same order onboth computers. Make sure you have a home directory for testuser1 on **lab1**.

```bash
sudo adduser --disabled-password --gecos "" --uid 1002 testuser1
sudo adduser --disabled-password --gecos "" --uid 1003 testuser2
```



## 2 Configuring and testing NFS

NFS is an acronym for "network filesystem". NFS is implemented for nearly all unix variations and even for windows.

Make sure you have nfs-kernel-server installed on **lab1**. Export /home directory via [/etc/exports](http://tldp.org/HOWTO/NFS-HOWTO/server.html). Restart the NFS server daemon. Mount **lab1**:/home to **lab2**:/mnt. You can change user with su, e.g. "su testuser1". Test that NFS works by writing a file in **lab1**:/home/testuser1/test.txt and open the same file at **lab2**:/mnt/testuser1/test.txt.



### 2.1 Demonstrate a working configuration.

Configuration:

On lab1,

```bash
# export /home
sudo tee -a /etc/exports <<EOL
/home lab2(rw,sync,no_subtree_check)
EOL

# restart NFS
sudo systemctl restart nfs-kernel-server.service
```

On lab2,
```bash
# mount
sudo mount -t nfs lab1:/home /mnt

#sudo umount /mnt
```

Test:

On lab1,
```bash
sudo -u testuser1 tee /home/testuser1/test.txt <<< "Hello world"
```

On lab2,

```bash
sudo -u testuser1 cat /mnt/testuser1/test.txt
```





### 2.2 Is it possible to encrypt all NFS traffic? How?

Yes:

1. **Use NFS version 4 (NFSv4)**: NFSv4 provides built-in support for stronger security mechanisms compared to earlier versions of NFS. It includes features like strong authentication and access control.
2. **Implement Kerberos Authentication**: Kerberos is a network authentication protocol that provides strong authentication for client-server applications by using secret-key cryptography. With Kerberos authentication, both the NFS server and clients authenticate each other using tickets issued by a Kerberos Key Distribution Center (KDC). This ensures that only authorized users can access NFS shares.



## 3 Configuring and testing samba

Samba is unix/linux implementation for normal Windows network shares(netbios and CIFS (common internet filesystem)). You can configure samba via */etc/samba/smb.conf*. You can access files shared with samba with command smbclient or by mounting the filesystem via mount, like with NFS. Mounting will require cifs-utils to be installed on **lab2**.

Start by unmounting with *umount(8)* the NFS directory in **lab2** from the previous assignment. If unmounting complains "resource busy", you have a shell with your current directory in the /mnt directory and you need to switch to another directory.

Make sure you have samba installed on **lab1**. Share /home with read and write permissions (/home shares are already at smb.conf but it needs a little bit of tweaking) and reload samba. Run smbpasswd on **lab1** and add testuser1 as a user. Try to mount *//lab1/home/testuser1* to **lab2**:/mnt with username testuser1 and testuser1's password. If it doesn’t work, check that necessary services and ports are open.



### 3.1 Demonstrate a working configuration.

Configuration:

On lab1,
```bash
sudo tee -a /etc/samba/smb.conf <<EOL
[homes]
   path = /home
   browseable = yes
   read only = no
   create mask = 0775
   directory mask = 0775
EOL

sudo systemctl reload smbd.service

sudo smbpasswd -a testuser1 # ask for password

sudo smbpasswd -e testuser1
```

On lab2,
```bash
# mount
sudo mount -t cifs -o username=testuser1 -o password=123456 //lab1/home/testuser1 /mnt

# sudo umount /mnt
```

Test:
On lab2,

```bash
cat /mnt/test.txt
```







### 3.2 Only root can use mount. What problem does this pose for users trying to access their remote home directories? Is there a workaround for the problem?

The problem with only allowing root to use mount is that regular users will not be able to mount network filesystems on their own, including their remote home directories. This can be inconvenient and limit their ability to access and work with their files.

However, there is a workaround for this problem. 

- One way is to add an entry to the /etc/fstab file that specifies the network filesystem and its mount point. This will allow the network filesystem to be mounted at boot time by the system, with the proper permissions for the specified user. 
- Another way is to use the mount command with the suid bit set, which allows users to mount network filesystems as themselves instead of root. However, this method may introduce security risks and is generally not recommended. 
- A third way is to use the "-o" to specify the user and group that should be used to mount the filesystem.



## 4 Configuring and testing sshfs

*sshfs* is filesystem for FUSE (filesystem in userspace).

Start by unmounting the samba share on **lab2**.

Next mount **lab1**:/home/testuser1 to **lab2**:/home/testuser1/mnt using *sshfs*. Demonstrate this to the assistant.



### 4.1 Provide the commands that you used.

Command:
On lab2,

```bash
sudo -u testuser1 mkdir /home/testuser1/mnt

sudo -u testuser1 sshfs lab1:/home/testuser1 /home/testuser1/mnt

# sudo -u testuser1 fusermount -u /home/testuser1/mnt
# sudo -u testuser1 umount /home/testuser1/mnt
```

Test:
On lab2,

```bash
sudo -u testuser1 cat /home/testuser1/mnt/test.txt
```



### 4.2 When is *sshfs* a good solution?

sshfs can be a good solution when you need to **securely access files on a remote server over a network** (You already have a ssh setup). It uses encryption to protect data during transmission, making it more secure than some other network filesystems. It also provides a familiar interface for users, as files on the remote server can be accessed and manipulated through a regular file system interface. It also provides a way to access files on a remote server as a normal user on the local system.



### 4.3 What are the advantages of FUSE?

FUSE (Filesystem in Userspace) provides a way for filesystems to be implemented entirely in user space rather than in the kernel. This has several advantages:

- Increased flexibility: Because FUSE filesystems are implemented in user space, they can be written in any programming language and can use any libraries that are available for that language. This makes it easier to develop custom filesystems that meet specific needs.
- Improved stability: Because FUSE filesystems run in user space, errors and crashes in the filesystem code will not crash the entire system or cause data loss.
- Increased security: FUSE filesystems run with the permissions of the user who mounted them, which can help prevent security issues that arise from running code in kernel space.



### 4.4 Why doesn't everyone use encrypted channels for all network filesystems?

- Performance: Encryption can add overhead to network filesystem operations, which can slow down the system and reduce performance.
- Complexity: Implementing encryption for network filesystems can be complex and may require additional software or hardware.
- Compatibility: Encrypted channels may not be supported by all network filesystems or may require specific configuration settings or software to be used.
- Convenience: Encrypted channels can make it more difficult to share files and access them from different devices, especially if the devices are not set up to use the same encryption protocols or keys.



## 5 Configuring and testing WebDAV

WebDAV (Web-based Distributed Authoring and Versioning) is a set of extensions to the HTTP protocol which allows users to collaboratively edit and manage files on remote web servers.

In this exercise we'll use the built-in WebDAV module of Apache2 server platform. Check that *apache2* is installed and enable the dav_fs module. Restart *apache2 every time after enabling a module*.

Create a directory */var/www/WebDAV for storing WebDAV related files and add subdirectory files* to be shared using WebDAV. Change the owner of the directories created to *www-data* (Apache's user ID) and the group to your user ID. Change the permissions if needed.

Create an alias to the virtual host file (*/etc/apache2/sites-available/000-default.conf*) so that /var/www/WebDAV/files can be reached through *http://localhost/webdav*. Enable the virtual host by creating a symbolic link between */etc/apache2/sites-available/000-default.conf* and */etc/apache2/sites-enabled/*.

Restart *apache2* and check that you can reach the server with, for example, *elinks(1)*.

**Set up Authorization**

Enable the *auth_digest* module for apache. Create a password file for a testuser with *htdigest(1) to /var/www/WebDAV*. Edit permissions of the file so that only *www-data* and root can access it. Use the following template to add the location to the virtual host file:

```
<Location /webdav>
 DAV On
 AuthType Digest
 AuthName "your_auth_name"
 AuthUserFile path_to_your_password_file
 Require valid-user
</Location>
```

Restart Apache2 and test the server from another machine using *cadaver(1)*. You should reach the server *http://lab1/webdav* .



### 5.1  Demonstrate a working setup. (View for example a web page on one machine and edit it from another using cadaver).

Setup WebDAV:
On lab1,

```bash
sudo a2enmod dav
sudo a2enmod dav_fs
sudo a2enmod auth_digest
sudo systemctl restart apache2

sudo mkdir -p /var/www/WebDAV/files

sudo chown -R www-data:vagrant /var/www/WebDAV
sudo chmod -R 775 /var/www/WebDAV

sudo sed -i 's#</VirtualHost># \
	Alias /webdav /var/www/WebDAV/files \
	<Directory /var/www/WebDAV/files> \
		DAV On \
		Options Indexes FollowSymLinks \
		AllowOverride None \
		Require all granted \
	</Directory> \
</VirtualHost>#g' /etc/apache2/sites-available/000-default.conf

sudo systemctl restart apache2

# elinks http://localhost
# elinks http://localhost/webdav
```

Setup authorization:
On lab1,

```bash
sudo htdigest -c /var/www/WebDAV/.htdigest testuser testuser
# sudo cat /var/www/WebDAV/.htdigest

sudo chown www-data:root /var/www/WebDAV/.htdigest
sudo chmod 640 /var/www/WebDAV/.htdigest

sudo sed -i 's#</VirtualHost># \
	<Location /webdav> \
		DAV On \
		AuthType Digest \
		AuthName "testuser" \
		AuthUserFile /var/www/WebDAV/.htdigest \
		Require valid-user \
	</Location> \
</VirtualHost>#g' /etc/apache2/sites-available/000-default.conf

sudo systemctl restart apache2
```

Test:
On lab2,

```bash
echo "<head>hello world from lab2" > hello.html

cadaver http://lab1/webdav
# testuser
# 123456
put /home/vagrant/hello.html
```

On lab1,
```bash
elinks http://localhost/webdav/hello.html
```





### 5.2 Demonstrate mounting a WebDAV resource into the local filesystem.

On lab2,

```bash
sudo mkdir /mnt/webdav
sudo mount -t davfs http://lab1/webdav /mnt/webdav
# testuser
# 123456

ls -l /mnt/webdav

# sudo umount /mnt/webdav
```



### 5.3 Does your implementation support versioning? If not, what should be added?

No, it doesn't.

To enable versioning, you can use a third-party WebDAV server software such as DeltaV that supports versioning or use a versioning file system like ZFS or Btrfs



## 6 Raid5

In this task, you are going to establish a Network Attached Storage (NAS) system with lab1 as a server. The server should use Raid for data integrity. Set up Raid 5 on the NAT server and create EXT4 filesystem on the array.

You need at least three partitions to do this, you can either partition current storage or add more virtual storage to your virtual machine. Then use [mdadm](https://manpages.ubuntu.com/manpages/trusty/man8/mdadm.8.html) tool to create the raid 5. Share the NAS device you setup with NFS.



### 6.1 What is raid? What is parity? Explain raid5?

RAID stands for Redundant Array of Independent Disks. It is a technology used to combine multiple physical hard drives into a single logical drive to increase storage capacity, data redundancy, and performance.

Parity is a method used in RAID technology to ensure data redundancy. It involves storing redundant information (parity data) across the disks in the RAID array, which can be used to reconstruct lost data in the event of a disk failure. It is a mathematical calculation that is performed on the data being written to the disk. This calculation generates an additional bit of data called a parity bit, which is then written to the disk alongside the original data.

RAID5 is a type of RAID configuration that uses block-level striping and parity data across three or more hard drives. In a RAID5 array, data is written across all the disks in the array, along with an additional parity block. This parity block is used to calculate the contents of any missing block if one of the disks fails. RAID5 provides fault tolerance and data redundancy with the smallest amount of overhead (only one disk’s worth of space is used for parity information).



### 6.2 Show that your raid5 solution is working.

On lab1:
```bash
# lsblk

# create 3 partitions for /dev/sdb (each with 2.5MB)
sudo fdisk /dev/sdb

sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sdb1 /dev/sdb2 /dev/sdb3

sudo mkfs.ext4 /dev/md0

# sudo mdadm --detail /dev/md0
```





### 6.3 Access the NAS device from lab2 over NFS

On lab1:
```bash
# mount
sudo mkdir /mnt/raid5
sudo mount /dev/md0 /mnt/raid5
#df -h

# suthority
sudo chmod 777 /mnt/raid5

# export
sudo tee -a /etc/exports <<EOL
/mnt/raid5 *(rw,sync,no_subtree_check)
EOL

# restart
sudo systemctl restart nfs-kernel-server
```

On lab2:
```bash
sudo mkdir /mnt/raid5
sudo mount -t nfs lab1:/mnt/raid5 /mnt/raid5

cp ~/test.txt /mnt/raid5/test.txt
# sudo umount /mnt/raid5
```





## 7 Final question



### 7.1 Describe briefly a few use cases for *samba*, *nfs*, *sshfs* and *WebDAV*. Where, why, weaknesses?

Samba:

- Use case: Sharing files and printers between Linux and Windows machines on a local network.
- Where: Offices, homes, or any environment where both Linux and Windows machines need to share resources.
- Why: Samba provides seamless file and printer sharing between Windows and Linux machines, making it an ideal solution for mixed networks.
- Weaknesses: Samba can be difficult to configure, especially for complex setups with many users or shared resources.

NFS:

- Use case: Sharing files between Linux/Unix machines on a local network.
- Where: Large organizations or research labs with many Linux/Unix servers and clients that need to share files and collaborate on projects.
- Why: NFS is a mature and well-established network file system that provides fast and reliable file sharing between Linux/Unix machines.
- Weaknesses: NFS does not provide encryption or authentication, so it's not suitable for use over public networks or the internet without additional security measures.

SSHFS:

- Use case: Securely sharing files between remote Linux/Unix machines over the internet.
- Where: Remote workers, freelancers, or any environment where secure file sharing is required.
- Why: SSHFS uses the SSH protocol for encryption and authentication, making it a secure and reliable way to share files over the internet.
- Weaknesses: SSHFS can be slower than other file sharing protocols like NFS or Samba, especially over high-latency networks.

WebDAV:

- Use case: Collaboratively editing and managing files on remote web servers.
- Where: Organizations or teams that need to work on the same set of files remotely.
- Why: WebDAV provides a standardized way to edit and manage files over the internet, making it an ideal solution for remote teams that need to collaborate on projects.
- Weaknesses: WebDAV can be slow over high-latency networks, and it may not provide all the features and capabilities of a dedicated file sharing system like NFS or Samba. Additionally, WebDAV clients may be less widely available than other file sharing clients.