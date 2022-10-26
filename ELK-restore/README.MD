# ELK restore toolkit

Usage:

* __list_indexes.sh__ - provide csv list of snapshot ids and index ids that are available on snapshot storage. Modify internally grep to only catch needed ones. You can list all the snapshots to a file and this you can work with later.
* __restore.sh__ - restores snapshots specified in indexes.csv
* __delete.sh__ - delete indexes specified in indexes.csv
* __indexes.csv__ - input for restore and delete scripts, should be in format as coming from list_indexes.sh