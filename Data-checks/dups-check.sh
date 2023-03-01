function wrap {
    mkdir -p ${logPath}
    bridge=$1
    executeSql "${bridge}" "${query}" &
}

function executeSql {
    sfx=$RANDOM
    bridge=$1
    query='select block_number, count(block_number) from scanner_state group by (block_number) having COUNT(block_number) > 1 and block_number > (select block_number from scanner_state_log order by block_number limit 1);'
    blocks=$(kubectl run psql-client-dups-${bridge}-${sfx} --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query}"  2>/dev/null | awk '{print $1 "," $3}')
    kubectl delete pods/psql-client-dups-${bridge}-${sfx} --namespace blockchain-data  >/dev/null
    if [ $(echo "$blocks" | grep -e "[0-9]" | wc -l) -ne 0 ]; then
        for blk in $(echo "$blocks" | cut -d ',' -f 1)
        do
            echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $bridge - ERROR: block $blk is duplicated! >> ${logPath}/dups-${bridge}-latest.log
        done
    fi
    touch ${logPath}/dups-${bridge}-latest.log
    cat ${logPath}/dups-${bridge}-latest.log >> ${logPath}/dups-continuous.log
    cat ${logPath}/dups-${bridge}-latest.log | grep ERROR
}

logPath="${HOME}/datachecks-logs"

items="celo-mainnet celo-testnet ethereum-sepolia ethereum-mainnet ethereum-goerli polygon-mainnet polygon-mumbai bsc-mainnet bsc-testnet"

rm -f ${logPath}/dups-*-latest.log
for item in $items
do
wrap $item
done
wait


