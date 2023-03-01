function wrap {
    mkdir -p ${logPath}
    bridge=$1
    executeSql "${bridge}" "${query}" &
}

function executeSql {
    sfx=$RANDOM
    bridge=$1
    query='select * from scanner_state_log where (type = 2 OR type = 5 OR type = 14 OR type = 25) and timestamp > ((select timestamp from scanner_state order by timestamp desc limit 1) - 7200000);'
    query='select block_number, type from scanner_state_log where (type = 2 OR type = 5 OR type = 14 OR type = 25);'
    blocks=$(kubectl run psql-client-fails-${bridge}-${sfx} --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query}"  2>/dev/null | awk '{print $1 "," $3}')
    kubectl delete pods/psql-client-fails-${bridge}-${sfx} --namespace blockchain-data  >/dev/null
    if [ $(echo "$blocks" | grep -e "[0-9]" | wc -l) -ne 0 ]; then
        for blk in $(echo "$blocks" | grep -e "[0-9]")
        do
            echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $bridge - ERROR: block $(echo $blk | cut -d ',' -f 1) has fail record type $(echo $blk | cut -d ',' -f 2)! >> ${logPath}/fails-${bridge}-latest.log
        done
    fi
    touch ${logPath}/fails-${bridge}-latest.log
    cat ${logPath}/fails-${bridge}-latest.log >> ${logPath}/fails-continuous.log
    cat ${logPath}/fails-${bridge}-latest.log | grep ERROR
}

logPath="${HOME}/datachecks-logs"

items="celo-mainnet celo-testnet ethereum-sepolia ethereum-mainnet ethereum-goerli polygon-mainnet polygon-mumbai bsc-mainnet bsc-testnet"

rm -f ${logPath}/fails-*-latest.log
for item in $items
do
wrap $item
done
wait
