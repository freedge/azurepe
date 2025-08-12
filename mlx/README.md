

```bash
#vm1
ip link add name geneve0 type geneve id 1000 remote 10.0.0.5
ip link set geneve0 up
ip addr add 10.200.1.1/32 dev geneve0
ip route add 10.200.2.1/32 dev geneve0
ip link set geneve0 mtu 450
```

```bash
# vm2
ip link add name geneve0 type geneve id 1000 remote 10.0.0.4
ip link set geneve0 up
ip addr add 10.200.2.1/32 dev geneve0
ip route add 10.200.1.1/32 dev geneve0
ip link set geneve0 mtu 450
systemd-run -p DynamicUser=true -u iperf1 iperf3 -s -p 5201
systemd-run -p DynamicUser=true -u iperf2 iperf3 -s -p 5202
systemd-run -p DynamicUser=true -u iperf3 iperf3 -s -p 5203
systemd-run -p DynamicUser=true -u iperf4 iperf3 -s -p 5204
DLID=$(devlink health | grep -o -P 'auxiliary/[^:]*')
while sleep 0.2 ; do until sudo devlink health  diagnose $DLID reporter tx | grep stopped | grep true; do date ; done && date && ethtool -S eth1 && date && sleep 0.2 && ethtool -S eth1; done | tee ethtools
```

```bash
# from vm1:
iperf3 -c 10.0.0.5 -w 30k -t 80000 -P 42 -R
iperf3 -c 10.0.0.5 -w 25k -t 80000 -p 5204 -P 112
iperf3 -c 10.200.2.1 -p 5203 -t 80000 -R -P 64
iperf3 -c 10.200.2.1 -p 5202 -t 80000 -P 64
ping vm2
```

