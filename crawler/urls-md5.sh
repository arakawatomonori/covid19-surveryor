#!/bin/bash
set -e

###
### About
### grep.shで./tmpに収集した情報を結合し、ソートし、重複を取り除くスクリプト
###
### Dependency
### - make wget
### - make grep
###
### Usage
### - make aggregate
###

# 依存lib
. ./lib/url-helper.sh


# result.txtからURLのみを抜き出す
urls=$(cat ./tmp/grep-aggregate.txt | cut -d':' -f 1 | sed -z 's/\.\/www-data\///g')

echo "" > ./tmp/urls.txt

# URLを一回ファイルに書き出す
for url in $urls; do
    echo "$url" >> ./tmp/urls.txt
done

# sortしてuniqする
sort < ./tmp/urls.txt | uniq > ./tmp/urls-uniq.txt

echo "" > ./data/urls-md5.csv

for domain_and_path in `cat ./tmp/urls-uniq.txt`; do
    # domain=example.com
    domain=`echo $domain_and_path| cut -d'/' -f1 `
    # path=foo/bar.html
    path=`echo $domain_and_path | cut -d'/' -f 2-`
    # top_url=https://example.com/index.html
    top_url=`grep $domain --include="*.csv" ./data/*|cut -d',' -f 3`
    if [ $top_url = "" ]; then
            continue
    fi
    # schema=https:
    schema=`echo $top_url | cut -d'/' -f 1`
    # url=https://example.com/foo/bar.html
    url="$schema//$domain/$path"
    md5=`get_md5_by_url $url`
    echo "$md5,$url" >> ./data/urls-md5.csv
done