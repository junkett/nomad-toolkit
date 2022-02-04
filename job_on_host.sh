job=$1
if [ -z $1 ]; then
    echo "ERROR - no job name provided"
    exit 1
fi
allocs="$(nomad job allocs $job | grep running)"
nodes="$(nomad node status | grep -v Eligibility)"
declare -a result=()
echo "Job $job allocations are on these hosts:"

IFS='
'

for alloc in $allocs 
do
    nodeId=$(echo $alloc | awk '{print $2}')
    host_name=$(echo "$nodes" | grep $nodeId | awk '{print $3}')

    result+=($host_name)

done

sorted=($(sort <<<"${result[*]}"))
unset IFS

echo ${sorted[*]} | sed -e 's/ /\n/g'

