job_pattern=$1
target_host=$2
if [ -z $1 ]; then
    echo "ERROR - no job name pattern provided"
    exit 1
fi

jobs=$(nomad job status | grep $job_pattern | awk '{print $1}')

IFS='
'

for job in $jobs 
do
    
    hosts=$(./job_on_host.sh $job | sort -u )
    if [[ $hosts == "" ]]; then
        echo "No such jobs running..."
    else
        if [[ $target_host == "" ]]; then
            echo
            echo "$hosts"
        else
            echo
            target=$(echo "$hosts" | grep $target_host)
            echo "Job $job is running on host: $target"
        fi
    fi
done

unset IFS


