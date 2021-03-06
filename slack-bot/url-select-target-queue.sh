#!/bin/bash
set -e

# data/reduce-vote.csv の内容を redis の queue として投入する
# すでに投入済みの場合はスキップする

. ./lib/redis-helper.sh
. ./lib/url-helper.sh

namespace="vscovid-crawler-select-target"

while read line; do
    # 「#」で始まる csv 行はコメントとみなしスキップする
    if [[ $line =~ ^\# ]]; then
        continue
    fi

    orgname=`echo $line| cut -d',' -f 1`
    prefname=`echo $line| cut -d',' -f 2`
    url=`echo $line| cut -d',' -f 3`
    title=`echo $line| cut -d',' -f 4`
    desc=`echo $line| cut -d',' -f 5`
    md5=`get_md5_by_url $url`

    is_exists=`redis_exists_md5 $namespace $md5`
    if [ $is_exists = "0" ]; then
      redis-cli SET "$namespace:queue-$md5" "$url,$orgname,$title,$desc"
    fi
done < ./data/reduce-vote.csv
