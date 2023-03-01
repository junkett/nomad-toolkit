
function executeSql {
    sfx=$RANDOM
    Block=$(kubectl run psql-client-gaps-${chain}-${sfx} --namespace blockchain-data --image postgres:14 --attach --restart=Never -- psql -t -p 5432 -h ttm-bridge-${chain}-v1 -c "${query}"  2>/dev/null | awk '{print $1}')
    kubectl delete pods/psql-client-gaps-${chain}-${sfx} --namespace blockchain-data >/dev/null
    echo $Block
}

chain=$1

queryGap='SELECT s1.block_number + 1 FROM scanner_state as s1 LEFT JOIN scanner_state AS alt ON alt.block_number = s1.block_number + 1 WHERE alt.block_number IS NULL and s1.timestamp > ((select timestamp from scanner_state order by timestamp desc limit 1) - 604800000) ORDER BY s1.block_number ASC LIMIT 1;'
query=$queryGap
gapBlock=$(executeSql)
queryLast="select block_number from scanner_state ORDER by block_number desc limit 1;"
query=$queryLast
lastBlock=$(executeSql)
if [[ $(expr $lastBlock - $gapBlock) -gt 1000 ]]; then
    queryHigh="select block_number from scanner_state where block_number > $gapBlock order by block_number limit 1"
    query=$queryHigh
    highBlock=$(executeSql)

    kubectl config set-context  gke_ttm-production-c8d7_us-west1_gke-us-west1
    kubectl config set-context --current --namespace=blockchain-data

    echo "Scale down continuous block ingest for $chain"
    kubectl scale --replicas=0 deployment/continuous-$chain
    sleep 5
    echo "Run backfill for $chain from block: $gapBlock to block: $highBlock"
    argo submit --wait backfill-$chain.yaml -p backfill-from=$gapBlock -p backfill-to=$highBlock
    sleep 5
    echo "Scale up continuous block ingest for $chain"
    echo kubectl scale --replicas=1 deployment/continuous-$chain
else
    echo "No gaps found!"
fi
