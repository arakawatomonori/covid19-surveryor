#!/bin/bash
set -e

. ./lib/test-helper.sh

. ./lib/url-helper.sh

echo test get_domain_by_url
actual=`get_domain_by_url http://www.kantei.go.jp`
expect="www.kantei.go.jp"
assert_equal "$expect" "$actual"


echo test get_orgname_by_url
actual=`get_orgname_by_url https://www.mhlw.go.jp`
expect="厚生労働省"
assert_equal "$expect" "$actual"


echo test get_title_by_res
res=`wget -q -O - https://kantei.go.jp`
title=`get_title_by_res "$res"`
assert_equal "首相官邸ホームページ" "$title"

echo test get_title_by_res
res=`wget -q -O - https://www.city.funabashi.lg.jp/jigyou/shoukou/002/corona-jigyosha.html`
title=`get_title_by_res "$res"`
assert_equal "新型コロナウィルス感染症に関する中小企業者（農林漁業者を含む）・労働者への支援｜船橋市公式ホームページ" "$title"

echo test get_title_by_res
res=`wget -q -O - https://www.pref.oita.jp/soshiki/14040/sodanmadoguti1.html`
title=`get_title_by_res "$res"`
assert_equal "新型コロナウイルスの流行に伴う経営・金融相談窓口の開設について - 大分県ホームページ" "$title"



echo test get_desc_by_res https://www.pref.oita.jp/soshiki/14040/sodanmadoguti1.html
res=`wget -q -O - https://www.pref.oita.jp/soshiki/14040/sodanmadoguti1.html`
desc=`get_desc_by_res "$res"`
assert_equal "新型コロナウイルスの流行に伴う経営・金融相談窓口の開設について-大分県ホームページ トップページ&gt;組織からさがす&gt;経営創造・金融課&gt;新型コロナウイルスの流行に伴う経営・金融相談窓口の開設について 新型コロナウイルスの流行に伴う経営・金融相談窓口の開設について 新型コロナウイルスの流行に伴う経営・金融相談窓口の開設について大分県では、新型コロナウイルスの流行に伴い、中小企業・小規模事業者からの経営・金融相談に対応するため、下記のとおり特別相談窓口を開設します。記１名称大分県中小企業・小規模事業者経営・金融相談窓口２期間令和２年１月３１日（金）～７月３１日（金）９：００～１７：００（土曜、日曜及び祝日を除く）３担当課、電話番号商工観光労働部経営創造・金融課（経営に関すること）電話：097-506-3223（金融に関すること）電話：097-506-3226４相談内容中小企業・小規模事業者の経営、金融全般に関すること５その他次の機関でも相談を受け付けています。・大分県信用保証協会&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;保証一課（電話：097-532-8246)保証二課（電話：097-532-8247)経営支援課（電話：097-532-8296）・大分県商工会連合会経営支援課（電話：097-534-9507)・大分県中小企業団体中央会組織支援一課（電話：097-536-6331)&nbsp;・各商工会議所・商工会" "$desc"



echo test get_desc_by_res https://www.city.hamamatsu.shizuoka.jp/nousei/koronataioumtg.html
res=`wget -q -O - https://www.city.hamamatsu.shizuoka.jp/nousei/koronataioumtg.html`
desc=`get_desc_by_res "$res"`
assert_equal "【事業者募集】新型コロナウイルス感染症対策・一次産業者等マッチング事業について／浜松市 ホーム&gt;浜松市の新型コロナウイルス感染症に関する対応について&gt;【事業者募集】新型コロナウイルス感染症対策・一次産業者等マッチング事業について 浜松市の新型コロナウイルス感染症に関する対応について 浜松市新型コロナウイルス感染症対策本部会議 新型コロナウイルス感染症対策にともなう施設の臨時休館 新型コロナウイルス感染症対策にともなうイベント開催中止一覧（2020年4月20日～4月30日） 新型コロナウイルス感染症対策にともなうイベント延期一覧 新型コロナウイルス感染症対策にともなうイベント対応方針 【事業者募集】新型コロナウイルス感染症対策・一次産業者等マッチング事業について 新型コロナウイルス感染症対策・生産者等SOS掲示板について 新型コロナウイルス感染症対策にともなう事業者向け対策 新型コロナウイルス感染症の影響により納付が困難な方に対する令和2年度に課税される市税等における納税の猶予 新型コロナウイルス感染症対策にともなうイベント開催中止一覧（2020年5・6月） 新型コロナウイルスの感染が疑われる人がいる場合の家庭内での注意事項 新型コロナウィルス対策提案事業費補助金 新型コロナウイルス感染症拡大防止・緊急経済対策 【事業者募集】新型コロナウイルス感染症対策・一次産業者等マッチング事業について 新型コロナウイルス感染症の影響拡大を受け、一次生産者や加工販売業者などにおいて、売り上げの低迷や過剰在庫などの影響が出ております。市内の農水産物などの過剰在庫の解消や、販売促進を支援するため、このような事業者の情報をとりまとめ、流通関係者とのマッチング事業を行います。 【事業者募集】新型コロナウイルス感染症対策・生産者等SOS掲示板について&nbsp;" "$desc"


