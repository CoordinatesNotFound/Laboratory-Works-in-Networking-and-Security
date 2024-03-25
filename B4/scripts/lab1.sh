sudo apt-get install nfs-kernel-server samba elinks apache2 mdadm -y

sudo adduser --disabled-password --gecos "" --uid 1002 testuser1
sudo adduser --disabled-password --gecos "" --uid 1003 testuser2

sudo -u testuser1 mkdir /home/testuser1/.ssh
sudo -u testuser1 tee -a /home/testuser1/.ssh/id_ed25519 <<EOL
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDln5x14piy9zk7ixTXoJqEuZGvNwRgkrBpvS3mCdr1zwAAAJjHowqKx6MK
igAAAAtzc2gtZWQyNTUxOQAAACDln5x14piy9zk7ixTXoJqEuZGvNwRgkrBpvS3mCdr1zw
AAAEB4MS3Zs0YvSvfXQGBiJABRWdLhBxNXKQwWQ6w/TN9+ZOWfnHXimLL3OTuLFNegmoS5
ka83BGCSsGm9LeYJ2vXPAAAAEXlpbmFuLmh1QGFhbHRvLmZpAQIDBA==
-----END OPENSSH PRIVATE KEY-----
EOL

sudo -u testuser1 tee -a /home/testuser1/.ssh/id_ed25519.pub <<EOL
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWfnHXimLL3OTuLFNegmoS5ka83BGCSsGm9LeYJ2vXP yinan.hu@aalto.fi
EOL

sudo -u testuser1 tee -a /home/testuser1/.ssh/authorized_keys <<EOL
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWfnHXimLL3OTuLFNegmoS5ka83BGCSsGm9LeYJ2vXP yinan.hu@aalto.fi
EOL

sudo -u testuser1 chmod 600 /home/testuser1/.ssh/id_ed25519
