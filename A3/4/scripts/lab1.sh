
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

sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.default.forwarding=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.enp0s3.accept_ra=0



 
# sudo ip route del default via 10.0.2.2

# # ipv6 over ipv4 tunnel: 6rd
# sudo modprobe sit

# sudo ip tunnel add 6rd mode sit local 192.168.2.1 ttl 64
# sudo ip tunnel 6rd dev 6rd 6rd-prefix 2001:db8::/32
# sudo ip addr add 2001:db8:c0a8:0101::1/32 dev 6rd
# sudo ip link set 6rd up

# sudo route add default gw 192.168.2.1
# sudo route -6 add default gw ::192.168.2.1


# # ipv4 over ipv6 tunnel: ip4ip6
# sudo ip -6 tunnel add ip6tnl1 mode ip4ip6 remote fd01:2345:6789:abc1::2 local fd01:2345:6789:abc1::1
# sudo ip link set dev ip6tnl1 up
# sudo ip -6 route add fd01:2345:6789:abc1:: dev ip6tnl1 metric 1

#================================
sudo ip route del default via 10.0.2.2

sudo ip6tables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o enp0s9 -j MASQUERADE

# ipv6 over ipv4 tunnel: 6rd
sudo modprobe sit
sudo route add default gw 192.168.2.1

sudo ip tunnel add 6rd mode sit local 192.168.1.1 ttl 64
sudo ip tunnel 6rd dev 6rd 6rd-prefix 2001:db8::/32
sudo ip addr add 2001:db8:c0a8:101::1/32 dev 6rd
sudo ip link set 6rd up

sudo ip -6 route del fd01:2345:6789:abc2::/64 dev enp0s9
sudo ip -6 route add fd01:2345:6789:abc2::/64 via ::192.168.2.1 dev 6rd
sudo ip -6 route add 2001:db8:c0a8:201::/64 via ::192.168.2.1 dev 6rd
# sudo route -6 add default gw ::192.168.2.1

# ipv4 over ipv6 tunnel: ip4ip6
sudo ip -6 tunnel add ip6tnl1 mode ip4ip6 remote fd01:2345:6789:abc1::2 local fd01:2345:6789:abc1::1
sudo ip link set dev ip6tnl1 up
sudo ip -6 route add fd01:2345:6789:abc1:: dev ip6tnl1 metric 1
sudo ip addr add 10.0.1.1/24 dev ip6tnl1

