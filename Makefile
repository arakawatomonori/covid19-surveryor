
include .env
export $(shell sed 's/=.*//' .env)
ENV=$(environment)

.PHONY: all
all: usage

.PHONY: usage
usage:
	@cat USAGE

.PHONY: test
test:
	./test/test.sh

.PHONY: clean
clean:
	rm -f tmp/*
	rm -f www-data/index.html
	rm -f www-data/index.json

###
### 一番最初にwgetでクローリングをする
###
.PHONY: wget
wget:
	# csv内の全ドメインをwww-data以下にミラーリングする
ifeq ($(ENV),production)
	./crawler/wget.sh data/gov.csv data/pref.csv data/city.csv
else
	./crawler/wget.sh data/test.csv
endif
	# tmp/urls.txt内の全URLをwww-data以下にミラーリングする
	# tmp/urls.txtは「経済支援制度ですか？」に「はい」と答えられたURLのみ
	cd www-data
	cat ../tmp/urls.txt |xargs -I{} wget --force-directories --no-check-certificate {}
	cd -

###
### wgetで収集したwww-data内の巨大なファイルを削除する
###
.PHONY: remove-large-files
remove-large-files:
	./crawler/remove-large-files.sh

###
### wgetで収集したwww-data内のHTMLとPDFをgrepで検索する
###
.PHONY: grep
grep: tmp/grep_コロナ.txt.tmp

# tmp/grep_コロナ.txt.tmp を生成する
tmp/grep_コロナ.txt.tmp: remove-large-files
	./crawler/grep.sh

###
### grepの結果を集計する
### 複数のキーワードでgrepしているので重複があったりするのをuniqする
###
.PHONY: grep-aggregate
aggregate: tmp/grep_aggregate.txt

# tmp/grep_results.txt を生成する
tmp/grep_aggregate.txt: grep
	./crawler/grep-aggregate.sh

###
### grepの結果からURLのみを収集しmd5を計算する
###
.PHONY: urls-md5
urls-md5: data/urls-md5.csv

# tmp/urls-md5.csv を生成する
data/urls-md5.csv: tmp/grep_aggregate.txt
	./crawler/urls-md5.sh

###
### URLの一覧すべてをwgetし機械学習できるファイルにする
###
tmp/eval.csv: data/urls-md5.csv
	./auto-ml/urls-md5-csv-to-eval-csv.sh

###
### 機械学習で評価し結果を出力する
###
tmp/eval-result.csv: tmp/eval.csv
	sudo docker run --rm -v $(pwd)/../tmp:/tmp covid19surveyorml:latest eval /tmp/model.pkl --input_file /tmp/eval.csv > ../tmp/eval-result.csv

###
### 機械学習で評価した結果とURLのmd5を対応付ける
###
data/eval-results-md5.csv: tmp/eval-result.csv
	cat tmp/eval.csv|cut -d',' -f 1 > tmp/md5.csv
	paste -d ' ' tmp/md5.csv tmp/eval-result.csv > data/eval-results-md5.csv

# www-data/index.html, www-data/index.jsonを生成する
.PHONY: publish
publish: www-data/search/index.html www-data/map/index.json
ifeq ($(ENV),production)
	aws cloudfront create-invalidation --distribution-id E2JGL0B7V4XZRW --paths '/*'
endif

www-data/map/index.html:
	cd map-client && npm run build

www-data/map/index.json: www-data/map/index.html reduce.csv
	./lib/csv2json.sh "orgname" "prefname" "url" "title" "description" < reduce.csv > ./www-data/map/index.json

www-data/search/index.html: reduce.csv
	./crawler/publish.sh > ./www-data/search/index.html

###
### machine-larning
###





###
### slack-bot
###

# start
.PHONY: slack-bool-queue
slack-bool-queue:
	./slack-bot/url-bool-queue.sh

.PHONY: slack-bool-map
slack-bool-map:
	while true; do ./slack-bot/url-bool-map.sh; sleep 1; done

# redisのデータを集計しreduce.csvを生成する
.PHONY: slack-bool-reduce
slack-bool-reduce: reduce.csv

reduce.csv:
	./slack-bot/url-bool-reduce.sh > reduce.csv


# clear
.PHONY: slack-bool-clear-offer
slack-bool-clear-offer:
	redis-cli DEL vscovid-crawler:offered-members

# check
.PHONY: slack-bool-check-offer
slack-bool-check-offer:
	redis-cli SMEMBERS vscovid-crawler:offered-members

.PHONY: slack-bool-check-queue
slack-bool-check-queue:
	redis-cli KEYS vscovid-crawler:queue-*

.PHONY: slack-bool-check-jobs
slack-bool-check-jobs:
	redis-cli KEYS vscovid-crawler:job-*

.PHONY: slack-bool-check-results
slack-bool-check-results:
	redis-cli KEYS vscovid-crawler:result-*
