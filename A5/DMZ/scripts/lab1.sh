


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


sudo nft add table ip nat
sudo nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }


sudo nft add rule ip nat prerouting tcp dport 8080 dnat to 192.168.0.3:80

sudo nft add chain ip nat postrouting { type nat hook postrouting priority 0 \; }

sudo nft add rule ip nat postrouting oif enp0s3 masquerade



sudo nft add table inet filter

sudo nft add chain inet filter input { type filter hook input priority 0 \; }

sudo nft add chain inet filter output { type filter hook output priority 0 \;  }


sudo nft add chain inet filter forward { type filter hook forward priority 0 \;  }




sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter input tcp sport 80 accept
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input tcp dport 8080 accept
sudo nft add rule inet filter input drop

sudo nft add rule inet filter output oif lo accept
sudo nft add rule inet filter output tcp dport 80 accept
sudo nft add rule inet filter output tcp sport 22 accept
sudo nft add rule inet filter output tcp sport 8080 accept
sudo nft add rule inet filter output drop



sudo nft add rule inet filter forward iif enp0s9 oif enp0s8 ct state new,related,established accept
sudo nft add rule inet filter forward iif enp0s8 oif enp0s9 ct state related,established accept
sudo nft add rule inet filter forward drop


