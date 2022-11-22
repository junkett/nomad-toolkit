#!/bin/bash

function wrap {
    mkdir -p ${logPath}
    bridge=$1
    query='select state,count(block_number) from nft group by state;'
    executeSql "${bridge}" "${query}" > ${logPath}/nft-${bridge}-latest.log &
}

function executeSql {
    sfx=$RANDOM
    bridge=$1
    query=$2
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $bridge
    kubectl run psql-client-nftmeta-${bridge}-${sfx} --namespace blockchain-data --image postgres:14 --attach  --restart=Never -- psql -p 5432 -h ttm-bridge-${bridge}-v1 -c "${query}" 2>/dev/null
    kubectl delete pods/psql-client-nftmeta-${bridge}-${sfx} --namespace blockchain-data >/dev/null
}

logPath="~/datachecks-logs"

items="celo-mainnet celo-testnet ethereum-sepolia ethereum-mainnet ethereum-goerli polygon-mainnet polygon-mumbai bsc-mainnet"

for item in $items
do
wrap $item
done
wait
for item in $items
do
    pm_latest=$(grep ' 1 \| 2 \| 3 \| 4 ' ${logPath}/nft-${item}-latest.log | awk '{print $3}')
    tot=0
    for i in ${pm_latest[@]}; do
    let tot+=$i
    done
    pm_remaining=$(grep ' 0 ' ${logPath}/nft-${item}-latest.log | awk '{print $3}')
    if [ -z $pm_remaining ]; then
        pm_remaining=0
    fi
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - ${item} - processed: $tot remaining: $pm_remaining"  >> ${logPath}/nft.log
    tail -1 ${logPath}/nft.log
done


