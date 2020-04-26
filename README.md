getTweets.sh
============

getTweets.sh is a quick and simple Bash script, for fetching tweets from a specific user. This script uses twitter guest token, so there is absolute no need to either register official twitter API access or to login twitter account. The output is a json file for the further analysis. Yep, quick & simple.

## Dependency

- [jq](https://stedolan.github.io/jq/)
- [pup](https://github.com/EricChiang/pup)

## How to use

```
Usage:
  ./getTweets.sh -u <twitter_handle> [-m <max_num>] [-d]

Options:
  -u <handle>        Mandatory, set twitter handle
  -d                 Optional, direct output without saving to json file
  -m                 Optional, max tweets number to download
  -h | --help        Display this help message
```

### Example

- Fetch tweets from `kevcui`:

```
~$ ./getTweets.sh -u kevcui
```

All downloaded tweets will be stored in a json file, format like: `<handle>_<timestamp>.json`
