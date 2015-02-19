# nicorank

yet another niconico ranking maker ?

## what is this

* video list editor (web app)
* net info salvager (mechanize custom)
* and, so...


* [future works] image editor/previewer
* [imagine works] video spliter/joiner

## test run

* startup rails

```
 git clone https://github.com/ippo/nicorank
 cd nicorank
 bundle install
 # or, sudo bundle install
 # or, su; bundle insall
 # input your password if required
```

* create config and etc

```
 ./bin/sample_setup.rb
 #->./private/day/voso.yml # password
 #->./public/day/voso.yml  # title, search tag, and etc
 #->./public/day/voso      # data dir
```

* count up

```
 ./bin/day_count.rb
 #<-./lib/salvage.rb
 #<-./lib/nico_salvage.rb
 #<-./public/day/voso.yml
 #->./db/cache/YYYY/MM/DD/...      # cache of web pages
 #->./db/info/YYYY/MM/DD/...       # yaml: parsed info of cache pages
 #->./public/day/voso/YYYYMMDD.yml # yaml: update list (yesterday)
```

wait about 5min

* wakeup rails

```
 rails s -b 0.0.0.0
```

* edit list

```
 browse;
   localhost:3000/day/voso
   localhost:3000/day/voso/YYYYMMDD
   localhost:3000/day/voso/YYYYMMDD.txt
   localhost:3000/day/voso/YYYYMMDD/edit
 #<-./public/day/voso/YYYYMMDD.yml # yaml: list
 #<-./public/day/voso/YYYYMMDD.opt # yaml: options
 #->./public/day/voso/YYYYMMDD.opt # yaml: options(edit and write)
 #<-./public/day/voso/YYYYMMXX.opt # yaml: yesterday options
 #<-./public/day/voso.yml  # yaml: config
 #<-./private/day/voso.yml # yaml: password
```

* cron count up

```
 ./bin/fake_cron.rb
 # call day_count.rb in everyday 4:05, 12:05
 # or, edit crontab if you need
```

## customize

create/edit file and dir

```
 ./private/day/:code.yml # password
 ./public/day/:code.yml  # title, search tag, and etc
 ./public/day/:code      # data dir
 ./bin/day_count.rb
 ./app/controllers/day_controller.rb copy_option
 ./app/views/day/_item.html.slim
 and etc
```

# references

niconico daily vocaloid ranking

* [【日刊ぼかさん】日刊ランキングVOCALOID＆something](http://www.nicovideo.jp/mylist/47849908) ヒゲノフ・ダンスカヤ＠るかなんP 2015/1/12-
  * [るかなんPのブルマと巨乳と大人の都合](http://ch.nicovideo.jp/otonano-tugou)
* [Daily Vocaloid](http://www.nicovideo.jp/mylist/47796966) ＞＜カニ 2015/1/1-
  * [とりあえず作っただけです](http://ch.nicovideo.jp/torima)
* [ボーカロイド新着ダイジェスト](http://www.nicovideo.jp/mylist/47650787) あなたの天然記念物 2015/1/1-

* [closed] [日刊VOCALOIDランキング](http://www.nicovideo.jp/mylist/5024496) rankingloid 2008/2/11-2011/8/23
  * [日刊VOCALOIDランキング](http://blog.daily-vocaran.info)
* [closed] [日刊VOCALOIDランキング(YAMAHA)](http://www.nicovideo.jp/mylist/26314887) 2011/10/14-2015/1/31

* [ニコニコランキングメーカー配布サイト](http://www.daily-vocaran.info/nicorank)

please tell me if you know others
