indexes="$(cat indexes.csv)"
for index in $indexes
do
    snapshot=$(echo $index | cut -d, -f2 | tr -d '"')
    index_name=$(echo $index | cut -d, -f1 | tr -d '"')
    curl --location --request POST "https://search-tatum-logs-szyup4lpz7n4f2m3j4qfexweue.eu-west-1.es.amazonaws.com/_snapshot/ttm-logs-snapshots/$snapshot/_restore" --header 'Content-Type: application/json' --data-raw "{\"indices\": \"$index_name\"}"
done
