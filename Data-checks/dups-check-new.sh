function wrap {
    mkdir -p ${logPath}
    bridge=$1
    executeSql "${bridge}" "${query}" &
}

function executeSql {
    sfx=$RANDOM
    bridge=$1
    query='select block_number, count(block_number) from scanner_state group by (block_number) having COUNT(block_number) > 1;'
    blocks=$(kubectl run psql-client-dups-${bridge}-${sfx} --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query}"  2>/dev/null | awk '{print $1 "," $3}')
    kubectl delete pods/psql-client-dups-${bridge}-${sfx} --namespace blockchain-data  >/dev/null
    if [ $(echo "$blocks" | sed '/^,/d'| grep -e "[0-9]," | wc -l) -ne 0 ]; then
        qBlocks=$(echo "$blocks" | sed '/^,/d'| paste -sd ";" - | sed 's/;/ \)\) OR \( block_number=/g' | sed 's/,/ AND count\(block_number\) < \(-1 + /g')
        query2="select block_number from scanner_state_failed group by (block_number) having ( block_number = ${qBlocks} ));"
        res=$(kubectl run psql-client-dups-${bridge}-${sfx}-1 --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query2}" 2>/dev/null )
        kubectl delete pods/psql-client-dups-${bridge}-${sfx}-1 --namespace blockchain-data  >/dev/null
        if [ $(echo $res | wc -l) -gt 0 ]; then
            for blk in $res
            do
                echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $bridge - ERROR: block $blk is duplicated! >> ${logPath}/dups-${bridge}-latest.log
            done
            touch ${logPath}/dups-${bridge}-latest.log
            cat ${logPath}/dups-${bridge}-latest.log >> ${logPath}/dups-continuous.log
            cat ${logPath}/dups-${bridge}-latest.log | grep ERROR
        fi
    fi
}

logPath="${HOME}/datachecks-logs"

items="celo-mainnet celo-testnet ethereum-sepolia ethereum-mainnet ethereum-goerli polygon-mainnet polygon-mumbai bsc-mainnet"

rm -f ${logPath}/dups-*-latest.log
for item in $items
do
wrap $item
done
wait


