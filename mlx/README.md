
```bash
# both
# check udev rule well applied
# disable firewalld
systemd disable --now firewalld
```

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

systemd-run -p DynamicUser=true -u iperf1 iperf3 -s -p 5201 --interval 60
systemd-run -p DynamicUser=true -u iperf2 iperf3 -s -p 5202 --interval 60
systemd-run -p DynamicUser=true -u iperf3 iperf3 -s -p 5203 --interval 60
systemd-run -p DynamicUser=true -u iperf4 iperf3 -s -p 5204 --interval 60

DLID=$(devlink health | grep -o -P 'auxiliary/[^:]*')
VF=eth1
while sleep 0.2 ; do until devlink health diagnose $DLID reporter tx | grep stopped | grep true; do sleep 0.1 ; done && date && ethtool -S $VF && grep . /sys/class/net/${VF}/queues/tx-*/byte_queue_limits/inflight && sleep 0.2 && ethtool -S $VF && grep . /sys/class/net/${VF}/queues/tx-*/byte_queue_limits/inflight; done | tee ethtools
```

```bash
# from vm1:
systemd-run --user -u client1 iperf3 -c 10.0.0.5 -w 30k -t 80000 -P 42 -R -i 60
systemd-run --user -u client4 iperf3 -c 10.0.0.5 -w 25k -t 80000 -p 5204 -P 112 -i 60
systemd-run --user -u client3 iperf3 -c 10.200.2.1 -p 5203 -t 80000 -R -P 64 -i 60
systemd-run --user -u client2 iperf3 -c 10.200.2.1 -p 5202 -t 80000 -P 64 -i 60
systemd-run --user -u ping    ping vm2 -O
```
