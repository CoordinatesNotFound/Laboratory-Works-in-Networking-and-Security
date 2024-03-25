cat >> ~/.ssh/authorized_keys <<EOL
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWfnHXimLL3OTuLFNegmoS5ka83BGCSsGm9LeYJ2vXP yinan.hu@aalto.fi
EOL

sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.default.forwarding=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.enp0s3.accept_ra=0


# # ipv6 over ipv4 tunnel: 6rd
# sudo modprobe sit

# sudo ip tunnel add 6rd mode sit local 192.168.2.1 ttl 64
# sudo ip tunnel 6rd dev 6rd 6rd-prefix 2001:db8::/32
# sudo ip addr add 2001:db8:c0a8:0201::1/32 dev 6rd
# sudo ip link set 6rd up
# sudo ip -6 route add fd01:2345:6789:abc1::/64 via ::192.168.1.1 dev 6rd
# sudo ip -6 route add 2001:db8:c0a8:101::/64 via ::192.168.1.1 dev 6rd


# # sudo ip addr add 10.0.8.2/24 dev enp0s10

# # ipv4 over ipv6 tunnel: ip4ip6
# sudo ip -6 tunnel add ip6tnl1 mode ip4ip6 remote fd01:2345:6789:abc2::2 local fd01:2345:6789:abc2::1
# sudo ip link set dev ip6tnl1 up
# sudo ip -6 route add fd01:2345:6789:abc2:: dev ip6tnl1 metric 1
#=====================================


sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

sudo modprobe sit

# ipv6 over ipv4 tunnel: 6rd
sudo ip tunnel add 6rd mode sit local 192.168.2.1 ttl 64
sudo ip tunnel 6rd dev 6rd 6rd-prefix 2001:db8::/32
sudo ip addr add 2001:db8:c0a8:201::1/32 dev 6rd
sudo ip link set 6rd up

sudo ip -6 route del fd01:2345:6789:abc1::/64 dev enp0s9
sudo ip -6 route add fd01:2345:6789:abc1::/64 via ::192.168.1.1 dev 6rd
sudo ip -6 route add 2001:db8:c0a8:101::/64 via ::192.168.1.1 dev 6rd


# ipv4 over ipv6 tunnel: ip4ip6
sudo ip -6 tunnel add ip6tnl1 mode ip4ip6 remote fd01:2345:6789:abc2::2 local fd01:2345:6789:abc2::1
sudo ip link set dev ip6tnl1 up
sudo ip -6 route add fd01:2345:6789:abc2:: dev ip6tnl1 metric 1
sudo ip addr add 10.0.1.1/24 dev ip6tnl1
