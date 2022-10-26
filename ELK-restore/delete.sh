indexes="$(cat indexes.csv)"
for index in $indexes
do
    index_name=$(echo $index | cut -d, -f1 | tr -d '"')
    curl --request DELETE "https://search-tatum-logs-szyup4lpz7n4f2m3j4qfexweue.eu-west-1.es.amazonaws.com/$index_name"
done
