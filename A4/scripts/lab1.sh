
cat > ~/.ssh/id_ed25519 <<EOL
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDln5x14piy9zk7ixTXoJqEuZGvNwRgkrBpvS3mCdr1zwAAAJjHowqKx6MK
igAAAAtzc2gtZWQyNTUxOQAAACDln5x14piy9zk7ixTXoJqEuZGvNwRgkrBpvS3mCdr1zw
AAAEB4MS3Zs0YvSvfXQGBiJABRWdLhBxNXKQwWQ6w/TN9+ZOWfnHXimLL3OTuLFNegmoS5
ka83BGCSsGm9LeYJ2vXPAAAAEXlpbmFuLmh1QGFhbHRvLmZpAQIDBA==
-----END OPENSSH PRIVATE KEY-----
EOL

cat > ~/.ssh/id_ed25519.pub <<EOL
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWfnHXimLL3OTuLFNegmoS5ka83BGCSsGm9LeYJ2vXP yinan.hu@aalto.fi
EOL

cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

chmod 600 ~/.ssh/*

sudo modprobe dm_crypt aes
sudo apt-get install gocryptfs -y
