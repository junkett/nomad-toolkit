snapshots=$(cat snapshots_to_delete.csv)

for snapshot in $snapshots
do
    host="$(echo $snapshot | cut -d "," -f1)"
    snap_id="$(echo $snapshot | cut -d "," -f2)"
    ssh $host "sudo echo \"Deleting snapshot $snap_id\"; sudo zfs destroy $snap_id"
done