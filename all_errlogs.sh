job=$1
if [ -z $1 ]; then
    echo "ERROR - no job name provided"
    exit 1
fi
lines=50
allocs="$(nomad job allocs $job | grep running)"
nodes="$(nomad node status)"
IFS='
'
for alloc in $allocs
do
    id=$(echo $alloc | awk '{print $1}')
    task=$(echo $alloc | awk '{print $3}')
    nodeId=$(echo $alloc | awk '{print $2}')
    hostName=$(echo "$nodes" | grep $nodeId | awk '{print $3}')
    echo "Last $lines lines Logs for task $task alloc $id on host: $hostName:"
    echo "-----------------------------------------------------------------"
    nomad alloc logs -stderr -tail -n $lines $id $task
    echo "DONE ------------------------------------------------------------"
done

