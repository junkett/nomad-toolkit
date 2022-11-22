# Management Toolkit

Set of scripts to provide some shortcuts for easy ops management

## Tools

### Logging

* all_errlogs.sh - expects job name as an argument and will provide last 50 lines of stderr logs for all of the job allocations
* all_logs.sh - expects job name as an argument and will provide last 50 lines of logs for all of the job allocations

### Jobs

* job_on_host.sh - expects job name as an argument and will provide list of hosts (hostnames) where the job runs

### ELK restore toolkit

in ELK-restore folder - see its own readme for details

### Data checks

There is set of scripts that can be used to get information about following:
- Duplicated blocks ingested
- Gaps in ingested blocks
- State of NFT metadata ingestion