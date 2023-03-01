hosts=$(cat hosts_list.txt)
rm -f ./snapshots_to_delete.csv
touch ./snapshots_to_delete.csv
for host in $hosts
do
    snapshots=$(ssh $host "zfs list -t snapshot 2>/dev/null | awk '{print \$1}'| grep data-pool")
    for snapshot in $snapshots
    do 
        echo $host,$snapshot >> snapshots_to_delete.csv
    done
done