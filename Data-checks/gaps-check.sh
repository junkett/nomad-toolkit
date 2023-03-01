function wrap {
    mkdir -p ${logPath}
    bridge=$1
    executeSql "${bridge}" "${query}" > ${logPath}/gaps-${bridge}-latest.log &
}

function executeSql {
    sfx=$RANDOM
    bridge=$1

    queryGap='SELECT s1.block_number + 1 FROM scanner_state as s1 LEFT JOIN scanner_state AS alt ON alt.block_number = s1.block_number + 1 WHERE alt.block_number IS NULL and s1.timestamp > ((select timestamp from scanner_state order by timestamp desc limit 1) - 604800000) ORDER BY s1.block_number ASC LIMIT 1;'
    # queryGap='SELECT s1.block_number + 1 FROM scanner_state as s1 LEFT JOIN scanner_state AS alt ON alt.block_number = s1.block_number + 1 WHERE alt.block_number IS NULL ORDER BY s1.block_number ASC LIMIT 1;'
    gapBlock=$(kubectl run psql-client-gaps-${bridge}-${sfx} --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${queryGap}"  2>/dev/null | awk '{print $1}')
    kubectl delete pods/psql-client-gaps-${bridge}-${sfx} --namespace blockchain-data >/dev/null
    queryLast="select block_number from scanner_state ORDER by block_number desc limit 1;"
    lastBlock=$(kubectl run psql-client-gaps-${bridge}-${sfx}-1 --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${bridge}-v1 -c "${queryLast}" 2>/dev/null | awk '{print $1}')
    kubectl delete pods/psql-client-gaps-${bridge}-${sfx}-1 --namespace blockchain-data >/dev/null
    if [[ $(expr $lastBlock - $gapBlock) -gt 1000 ]]; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - $bridge - ERROR: there is a gap at block: $gapBlock and blockchain local tip is at $lastBlock!" #> ${logPath}/gaps-${bridge}-latest.log
    else
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - $bridge - INFO: there is no gap until now and blockchain local tip is at $lastBlock." #> ${logPath}/gaps-${bridge}-latest.log
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
cat ${logPath}/gaps-*-latest.log >> ${logPath}/gaps-continuous.log
cat ${logPath}/gaps-*-latest.log
