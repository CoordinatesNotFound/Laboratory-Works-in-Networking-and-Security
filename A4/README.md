

# A4: Encrypted Filesystems



## 0 Introduction

> Additional reading:
>
> - [Linux File System Introduction](https://tldp.org/LDP/intro-linux/html/intro-linux.html#chap_03)





### 0.1 Motivation

From a practical and sysadmin perspective, whether it’s from hackers breaking into your server, you losing your USB drive or your laptop getting stolen, it is a good rule of thumb to assume attackers can have access to your data. Suitably protecting your data with encryption can ensure the attackers don’t get access to your precious data ( [within a reasonably long time](https://en.wikipedia.org/wiki/Computational_hardness_assumption)).

Data protection can be conceptually divided into security of data at rest and security of data in transit. Data in transit then refers to data that is actively traversing networks. Unlike data in transit, data at rest is data that is not actively being transferred from one node to another in a network. This includes data stored in storage devices like hard drives, flash drives, solid state drives etc. Data protection at rest aims to secure this type of *static data.* While data at rest is sometimes considered to be less vulnerable than data in transit, it is often more valuable and once an attacker has physical access to it, easier to remove its data protection. Common data at rest encryption methods are of two broad types depending on their layer of operation:

1. Stacked filesystem encryption: Available solutions in this category are eCryptfs, gocryptfs and EncFS.
2. Block device encryption : The following "block device encryption" solutions are available, loop-AES, dm-crypt, TrueCrypt/VeraCrypt

The management of dm-crypt is done with the cryptsetup userspace utility. It can be used for the following types of block-device encryption: LUKS (default), plain, and has limited features for loopAES and Truecrypt devices.



### 0.2 Description of the exercise

In this exercise you will simulate encryption of an external memory (such as USB memory stick) using a file as the storage media. Simulation is used primarily because in many cases you have no physical access to the server machines (in addition, the servers are virtual). Two different schemes will be used: encrypted loopback device with dm_crypt and encryption layer for an existing filesystem with gocryptfs. However, we will begin by familiarizing with GPG and encrypting single files.



## 1 Preparation

You will need lab1 and lab2 for this assignment. Check that you have the following packages installed:

- cryptsetup
- gnupg
- haveged

Load the *dm_crypt* and *aes* kernel modules [lsmod(8), modprobe(8)]. Remove *cryptoloop* from use, if it's attached to the kernel.

For the fourth task, ensure that you have *gocryptfs* installed and *FUSE* is available. This should be done in a similar fashion as the earlier checks.



## 2 Encrypting a single file using GnuPG

Let's start with a simple encryption using GPG. Begin by creating a GPG keypair on both lab1 and lab2 using the RSA algorithm and 2048 bit keys. Exchange (and verify) the public keys between lab1 and lab2.

Create a plaintext file with some text in it on lab1. Encrypt the file using lab2's public key, and send the encrypted file to lab2. Now decrypt the file.

Finally, sign a plaintext file on lab2, send the file with its signature to lab1. Verify on lab1 that it really was the lab2 user that signed the message.



### 2.1 What are the differences between stacked file system encryption and Block device encryption?

Stacked file system encryption is encrypting individual files or directories within a file system, typically by adding a layer of encryption to an existing file system.

Block device encryption is encrypting the entire storage device like a hard drive or a USB.

Differences:

- Encryption scope:
  - Stacked file system encryption is applied at the file system level
  - Block device encryption is applied to the whole device, at the block level
- Encryption cost:
  - Stacked file system cost higher since it provide encryption for individual file systems
- Control granularity:
  - Stacked file system encryption has higer control granularity( more flexible), since it can encrypt only certain files or directories
  - Block device encryption provides a more secure, comprehensive encryption.
- Compatibility:
  - Stacked file system encryption may be more compatible with existing file systems, as encryption is applied at the file system level and does not require changes to the underlying disk layout.
  - Block device encryption may require specific support from the operating system and file system, as well as compatible hardware or software drivers for encryption support.



### 2.2 Provide the commands you used for creating and verifying the keys and explain what they do.

**To generate key-pair and export the public key**

On lab1:

```bash
# generate key
gpg --full-generate-key

# export to file
gpg --export -a "lab1-A4" > lab1-public.key

# exchange the public key
scp lab1-public.key vagrant@lab2:~/

# gpg --list-secret-keys --keyid-format=long
# gpg --fingerprint "lab2-A4"
```

On lab2:

```bash
gpg --full-generate-key

gpg --export -a "lab2-A4" > lab2-public.key

scp lab2-public.key vagrant@lab1:~/

# gpg --list-secret-keys --keyid-format=long
# gpg --fingerprint "lab1-A4"
```

**To encrypt the file on lab1 and decrypt it on lab2**

On lab1:

```bash
cat > plaintext.txt <<< "This is a secret from lab1 to lab2"

# import the public key of lab2
gpg --import lab2-public.key

# encrypt the file with public key of lab2
gpg -e -r "lab2-A4" plaintext.txt

# send to lab2
scp plaintext.txt.gpg vagrant@lab2:~/
```

On lab2:

```bash
# import the public key of lab1
gpg --import lab1-public.key 

# decrypt the file
gpg --decrypt plaintext.txt.gpg
```

**To sign the file on lab2 and verify it on lab1**

On lab2:

```bash
cat > message.txt <<< "This is a message from lab2 to lab1"

# sign with secret key of lab2
gpg --sign message.txt

# send to lab1
scp message.txt.gpg vagrant@lab1:~/
```

On lab1:

```bash
# verify with public key of lab2
gpg --verify message.txt.gpg
```



### 2.3 Are there any security problems in using GPG like this?

- Weak Passphrases: If the passphrase used to encrypt a GPG key is weak, it may be vulnerable to brute-force attacks
- Key Management: GPG keys may be vulnerable to theft or compromise, it they are not stored safely
- Key Verification: the public keys are verified based on the trust model. But it is important to verify the authenticity of GPG keys via trusted sources. Or it kay be vulnerable to man-in-the-middle attack



### 2.4  How does GPG relate to PGP?

GPG is an open-source implementation of the OpenPGP standard. GPG is compatible with PGP.

PGP (Pretty Good Privacy) was originally developed by Phil Zimmermann in the early 1990s as a proprietary software package for email encryption and digital signatures. It later became an open standard known as OpenPGP.





### 2.5 What is haveged and why did we install it earlier? What possible problems can usage of haveged have?

haveged is a software that generates random numbers based on the HAVEGE algorithm (based on variations in processor's voltage during operation). It is used to ensure that cryptographic operations have a steady and sufficient supply of entropy or randomness.

Key generation requires a source of randomness to make sure the generated key is secure enough, but some systems may not have enough entropy available to generate truly random numbers, so it may be vulnarable to attackers.

Problems:

- it may consume systems resources and influence the performance
- it may introduce new security risks if not configured properly



## 3 Crypto filesystem with loopback and device mapper

Next let's expand the encryption to cover an entire filesystem.

Create a file with random bytes to make it harder for the attacker to recognize which parts of device are used to store data, and which are left empty. This can be done with the command:

**dd if=/dev/urandom of=loop.img bs=1k count=32k**

Create a loopback device for the file using *losetup(8)*. Then using *cryptsetup(8)*, format the loopback device and map it to a pseudo-device. Please use LUKS with aes-cbc-essiv:sha256 cipher (should be default).

Create an ext2 filesystem on the pseudo-device, created in the previous step. The filesystem can be created with *mkfs.ext2(8)*.

After this, you have successfully created an encrypted filesystem into a file. The filesystem is ready, and requires a passphrase to be entered when you luksOpen it.

Now mount your filesystem. Create some files and directories on the encrypted filesystem. Check also what happens if you try to mount the system with a wrong key.



### 3.1 Provide the commands you used

```bash
# create a file with random bytes
dd if=/dev/urandom of=loop.img bs=1k count=32k

losetup -f
# /dev/loop3

# create a loopback device for the file
sudo losetup /dev/loop3 loop.img

# format the loopback device with LUKS encryption
sudo cryptsetup luksFormat /dev/loop3 --batch-mode

# open the encrypted device and map it to a pseudo-device (which is on /dev/mapper path)
sudo cryptsetup luksOpen /dev/loop3 secrets

# create an ext2 filesystem on the pseudo-device
sudo mkfs.ext2 /dev/mapper/secrets

# mount the encrypted filesystem
sudo mkdir /mnt/secrets
sudo mount /dev/mapper/secrets /mnt/secrets



# create files or dirs
cd /mnt/secrets
sudo touch testfile
sudo mkdir testdir


# unmount
sudo umount /mnt/secrets
sudo cryptsetup luksClose secrets
# type the wrong passphrase to luksOpen cmd
sudo cryptsetup luksOpen /dev/loop3 secrets
```



### 3.2 Explain the concepts of the pseudo-device and loopback device.

- Pseudo-deivce
  - Psudo-device is a device file that does not correspond to a physical device but behaves like one from a software perspective.
  - Pseudo-devices are used to provide access to system resources or functionalities through a file-like interface, allowing applications to interact with them 
  - e.g. /dev/urandom
- Loopback device
  - it is a special type of device that allows a file to be mounted as a filesystem, enabling file-based operations to be performed on it as if it were a physical disk or partition.
  - It means that a file can be treated as it it were a block device and a filesystem can be created within it.



### 3.3 What is LUKS?

LUKS (Linux Unified Key Setup)  is a disk encryption specification that provides a standard format for encrypted data on Linux systems. LUKS is typically used to encrypt the entire disk or a partition on a Linux system, but it can also be used to encrypt a loopback device or other block device.



### 3.4 What is this kind of encryption method (creating a filesystem into a large random file, and storing a password protected decryption key with it) good for? What strengths and weaknesses does it have?

It is good for creating encrypted containers or encrypted disk images. It refers to creating a virtual encrypted container, which is essentially a large file. It is treated as a file system and encrypted with a password, and all data stored within the container is also encrypted.

Strengths:

- Additional security layer
- Convenience for user

Weaknesses:

- Password weakness: vulnerable to brute force
- Single Point of Failure: If the passphrase protecting the container is compromised, all data within the container may be at risk. Additionally, if the container file itself becomes corrupted or damaged, it may result in data loss.
- Performance Overhead: Accessing data within the encrypted container may incur a performance overhead due to the encryption and decryption processes. This overhead can vary depending on factors such as encryption algorithm and hardware capabilities.



### 3.5 Why did we remove cryptoloop from the assignment and replaced it with dm_crypt? Extending the question a bit, what realities must a sysadmin remember with any to-be-deployed and already deployed security-related software?

Cryptoloop was a legacy encryption module in the Linux kernel that used a deprecated cryptographic algorithm, which made it vulnerable to some attacks. Because of this, it has been removed from newer versions of the Linux kernel in favor of more modern encryption modules like dm-crypt, which use more secure encryption algorithms.

Realities:

- Security vulnerabilities
- System performance
- Compatibility
- User Awareness and Training
- Compliance and Regulations



## 4 Gocryptfs

Using gocryptfs, mount an encrypted filesystem on a directory of your choice. This gives you the encryption layer. After this, create a few directories, and some files in them. Unmount gocryptfs using Fuse's fusermount.

Check what was written on the file system.



### 4.1 Provide the commands you used.

```bash
# create a directory to mount the encrypted filesystem
sudo mkdir /mnt/encrypted
sudo mkdir gocryptfs

# initialize the encrypted filesystem using gocryptfs
sudo gocryptfs -init ~/gocryptfs

# mount the encrypted filesystem using gocryptfs
sudo gocryptfs gocryptfs /mnt/encrypted


# create some directories and files in the mounted encrypted filesystem
sudo mkdir /mnt/encrypted/testdir1
sudo mkdir /mnt/encrypted/testdir2
sudo bash -c 'echo "Hello, world" > /mnt/encrypted/testdir1/testfile1.txt'

# unmount
sudo fusermount -u /mnt/encrypted
```







### 4.2 Explain how this approach differs from the loopback one. What are the main differences between gocryptfs and encFS? Is encFS secure?

The approach of using gocryptfs differs from the loopback approach in:

- Encryption granularity: With loopback encryption, the entire file system is encrypted as a single unit. With gocryptfs, individual files are encrypted and decrypted on-the-fly as they are accessed.
- Encryption algorithm: Gocryptfs uses a more modern and secure encryption algorithm (AES-256 in GCM mode) compared to the older and less secure encryption algorithm used by loopback encryption.
- Authentication: Gocryptfs uses a stronger and more secure password-based key derivation function (Argon2) to derive the encryption key from the user's password.

The main differences between gocryptfs and encFS:

- Encryption Algorithm:
  - Gocryptfs: Gocryptfs uses AES-256 in GCM mode for encryption, which is considered to be highly secure.
  - encFS: encFS typically uses AES-128 in CBC mode for encryption. 
- Security Model:
  - Gocryptfs: Gocryptfs is designed with a modern security model that aims to minimize the attack surface and protect against various threats, such as data leakage and metadata exposure.
  - encFS: encFS has been criticized for its security model, particularly regarding how it handles file metadata and encryption key management. There have been many concerns about its security
- Performance:
  - Gocryptfs: Gocryptfs is faster especially when dealing with large filesystems
  - encFS: The performance of encFS may degrade when dealing with large filesystems or files 

As for the security of encFS, it is generally considered to be less secure than some other encryption tools due to some potential vulnerabilities, such as the possibility of data leakage through temporary files, weak key derivation functions, and other security issues. ----- not suitable for high security requirement



## 5 TrueCrypt and alternatives

On this course we used to have a TrueCrypt assignment where students were required to create a hidden volume inside another volume. However, since 2014 there has been a lot of discussion about the security of TrueCrypt. Read arguments against and for TrueCrypt and based on your knowledge of the subject make a choice to use either TrueCrypt or one of the alternative forks that can create hidden volumes. Using the software of your choice create a hidden volume within an encrypted volume.

If you decide to use [veracrypt](https://www.veracrypt.fr/en/Home.html), the command line syntax for veracrypt is `veracrypt [OPTIONS] VOLUME_PATH [MOUNT_DIRECTORY]`and the options can be found by running`veracrypt -h`



### 5.1 Which encryption software did you choose and why?

I chose to use VeraCrypt. Because it is a widely used open-source software forked from TrueCrypt and is actively maintained with regular updates and security patches. Additionally, it has support for creating hidden volumes and plausible deniability.



### 5.2 Provide the commands that you used to create the volumes. Demonstrate that you can mount the outer and the hidden volume.

```bash
# install veracrypt
wget https://launchpad.net/veracrypt/trunk/1.25.9/+download/veracrypt-1.25.9-Ubuntu-22.04-amd64.deb
sudo dpkg -i veracrypt-1.25.9-Ubuntu-22.04-amd64.deb
sudo apt-get -f install -y

# create the keyfiles
head -c 2048 < /dev/urandom > outer_key
head -c 2048 < /dev/urandom > hidden_key

# create the outer volume
head -c 4000 </dev/urandom | veracrypt -c encrypted_volume --size=100M --encryption=AES --hash=SHA-512 --filesystem=Ext4 --volume-type=normal -p 123456 --pim=20 -k=outer_key

# create a hidden volume
head -c 4000 </dev/urandom | veracrypt -c encrypted_volume --size=50M --encryption=AES --hash=SHA-512 --filesystem=Ext4 --volume-type=hidden -p 123456 --pim=20 -k=hidden_key

# mount the outer volume
sudo mkdir /mnt/veracrypt
sudo veracrypt encrypted_volume /mnt/veracrypt -p 123456 --pim=20 -k=outer_key --protect-hidden yes --protection-password=123456 --protection-pim=20 --protection-keyfiles=hidden_key

# unmount the outer volume:
veracrypt --dismount encrypted_volume
```



### 5.3 What is plausible deniability?

Plausible deniability is a feature that allows a user to create an encrypted volume that appears to contain sensitive data, but can also contain a hidden volume with a separate password and data. This allows the user to reveal the password to the outer volume if forced, while keeping the existence of the hidden volume secret.