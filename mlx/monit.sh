dumpone() {
VF=$(ip -j link  | jq '.[] | select (.master == "eth0") | .ifname' -r)
BUS=$(ethtool -i $(ip -j link  | jq '.[] | select (.master == "eth0") | .ifname' -r) | grep -o -P '(?<=bus-info: ).*')
DLID=$(devlink health | grep -A 10 $BUS | grep -o -P 'auxiliary/[^:]*')

while sleep 0.2 ; do until devlink health diagnose $DLID reporter tx | grep stopped | grep true; do sleep 0.2 ; done && date && ethtool -S $VF && grep . /sys/class/net/${VF}/queues/tx-*/byte_queue_limits/inflight && devlink health diagnose $DLID reporter tx && sleep 0.2 && ethtool -S $VF && grep . /sys/class/net/${VF}/queues/tx-*/byte_queue_limits/inflight && devlink health diagnose $DLID reporter tx ; done > ethtools
}
export -f dumpone

while true ; do
        timeout 6h bash -c dumpone
        D=$(date +%d%b%H%M%S)
        grep -P 'tx\d+_packets: ' ethtools  | sort | uniq -c | sort -n | grep -v '   1 ' > ethtools.${D}.summary
        FILT=$(zgrep -o -P 'tx\d+_packets:.*' ethtools | sort | uniq -d | tr '\n' '|')
        zgrep -C 10000 -P "${FILT}xxxx"  ethtools  | grep -P 'UTC 2025|true|/tx|tx\d+_packets:' >> ethtools.${D}.summary
        mv ethtools ethtools.${D}
        gzip ethtools.${D} &
done
