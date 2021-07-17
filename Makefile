
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
### crawler
###

.PHONY: wget
wget:
	# csv内の全ドメインをwww-data以下にミラーリングする
ifeq ($(ENV),production)
	./crawler/wget.sh data/gov.csv data/pref.csv data/city.csv
	# TODO:
	#   tmp/urls.txt は aggregate.sh の準成果物であるはずだが、
	#   コマンド実行の順序は wget, grep, aggregate であるため、wget が tmp/urls.txt に依存する構造は破綻している.
	#   ここの処理内容については要改修と思われる.
	#
	# tmp/urls.txt 内の全URLを www-data 以下にミラーリングする
	# tmp/urls.txt は「経済支援制度ですか？」に「はい」と答えられた URL のみ (TODO: このコメントはおそらく間違っている. 要修正検討.)
	cd www-data
	cat ../tmp/urls.txt |xargs -I{} wget --force-directories --no-check-certificate {}
	cd -
else
	./crawler/wget.sh data/test.csv
endif

# www-data内の巨大なファイルを削除する
.PHONY: remove-large-files
remove-large-files:
	./crawler/remove-large-files.sh

# www-data内のHTMLとPDFをgrepで検索する
# tmp/grep_コロナ.txt.tmp を生成する
.PHONY: grep
grep: tmp/grep_コロナ.txt.tmp

tmp/grep_コロナ.txt.tmp: remove-large-files
	./crawler/grep.sh

# grep結果を集計する
#   複数のキーワードで grep しているので重複があったりするのを uniq し、URL の MD5 ハッシュも求める
#     成果物: data/urls-md5.csv, tmp/urls.txt を生成する
#     (TODO: tmp/urls.txt の利用用途が wget の入力値となっているが、これはコマンドの依存関係を破綻させているので、要改修検討)
.PHONY: aggregate
aggregate: data/urls-md5.csv

data/urls-md5.csv: grep
	./crawler/aggregate.sh

# www-data/index.html, www-data/index.jsonを生成する
.PHONY: publish
publish: www-data/search/index.html www-data/map/index.json
	@echo index files are generated

www-data/map/index.html:
	make -C map-client

www-data/map/index.json: www-data/map/index.html data/reduce-vote.csv
	./lib/csv2json.sh "orgname" "prefname" "url" "title" "description" < data/reduce-vote.csv > ./www-data/map/index.json

www-data/search/index.html: data/reduce-vote.csv
	./crawler/publish.sh > ./www-data/search/index.html

.PHONY: deploy
deploy:
	rm -f www-data/map/index.html www-data/map/index.json
	git checkout master
	git pull origin master
	make publish
ifeq ($(ENV),production)
	aws cloudfront create-invalidation --distribution-id E2JGL0B7V4XZRW --paths '/*'
	./slack-bot/post-git-commit-log.sh
else
	@echo "environment isn't production."
endif

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

.PHONY: slack-bool-reduce
slack-bool-reduce: data/reduce-bool.csv

data/reduce-bool.csv:
	./slack-bot/url-bool-reduce.sh > ./data/reduce-bool.csv

# redis のデータを集計し data/reduce-vote.csv を生成する
.PHONY: slack-vote-reduce
slack-vote-reduce: data/reduce-vote.csv

data/reduce-vote.csv:
	./slack-bot/url-vote-reduce.sh > ./data/reduce-vote.csv

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
