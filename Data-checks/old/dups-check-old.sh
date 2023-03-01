function wrap {
    mkdir -p ${logPath}
    bridge=$1
    executeSql "${bridge}" "${query}" &
}

function executeSql {
    sfx=$RANDOM
    bridge=$1
    query='select block_number from scanner_state where block_number < (select block_number from scanner_state_failed ORDER BY block_number DESC LIMIT 1) group by (block_number) having COUNT(block_number) > 1;'
    blocks=$(kubectl run psql-client-dups-${bridge}-${sfx} --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query}"  2>/dev/null | awk '{print $1}')
    kubectl delete pods/psql-client-dups-${bridge}-${sfx} --namespace blockchain-data >/dev/null
    if [ $(echo "$blocks" | grep -e "[0-9]" | wc -l) -ne 0 ]; then
        qBlocks=$(echo "$blocks" | paste -sd ";" - | sed 's/;/ OR block_number=/g')
        query2="select block_number from scanner_state_failed where block_number=${qBlocks};"
        res=$(kubectl run psql-client-dups-${bridge}-${sfx}-1 --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query2}" 2>/dev/null)
        kubectl delete pods/psql-client-dups-${bridge}-${sfx}-1 --namespace blockchain-data >/dev/null
        for blk in $blocks
        do
            if [ $(echo $res | grep $blk | wc -l) -eq 0 ]; then
                echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $bridge - ERROR: block $blk not in scanner_state_failed! > ${logPath}/dups-${bridge}-latest.log
            else
               echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $bridge - OK: block $blk is in scanner_state_failed! > ${logPath}/dups-${bridge}-latest.log
            fi
            cat ${logPath}/dups-${bridge}-latest.log >> ${logPath}/dups-continuous.log
            cat ${logPath}/dups-${bridge}-latest.log | grep ERROR
        done
    fi
}

logPath="${HOME}/datachecks-logs"

items="celo-mainnet celo-testnet ethereum-sepolia ethereum-mainnet ethereum-goerli polygon-mainnet polygon-mumbai bsc-mainnet bsc-testnet"

rm -f ${logPath}/dups-*-latest.log
for item in $items
do
wrap $item
done
wait


