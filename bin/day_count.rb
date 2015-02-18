#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# daily vocaloid and something ranking ?

$:.unshift './lib/'
require 'nico_salvage'

code = 'voso'
today = Date::today
end_time = Time::parse today.to_s
start_time = Time::parse (today - 7).to_s
# start_time <= check < end_time
limit = start_time
#keywords = ['VOCALOID',
#            'UTAU',
#            'CeVIOカバー曲 or ささらオリジナル曲'
#           ]
keywords = YAML::load_file("./public/day/#{code}.yml")[:keywords]

class Salvage::Page
  def initialize_custom ( config = @config )
    @cache.base_dir  = Pathname './db/cache/'
    @record.base_dir = Pathname './db/info/'
  end
end
client = NicoSalvage.new

#- tag_rss search
tag_items = []
page = nil
keywords.each{ |keyword|
  params = {keyword: keyword, sort: 'f'}
  limit_options = {limit: limit, key: 'pubDate'}
  page = client.pages_tag_rss params, limit_options
  items = page.info
  dir = Pathname(page.cache.filename_body).dirname + params[:keyword]
  page.record.dir = dir.to_s
  page.record.data = items
  page.record.save
  tag_items += items
}
dir = Pathname(page.cache.filename_body).dirname + code
page.record.dir = dir.to_s
page.record.data = tag_items
page.record.save

#- merge 7days tag_rss search video_id
video_ids = []
(start_time.to_date..end_time.to_date).each{ |day|
  dir = day.strftime "./db/info/%Y/%m/%d/**/tag_rss/#{code}.yml"
  Dir::glob(dir).each{ |file|
    videos = YAML::load_file(file).select{ |item| start_time <= item['pubDate'] }
    new_video_ids = videos.map{ |item| item[:video_id] }
    video_ids += new_video_ids
  }
}
video_ids.uniq!.sort!

#- getthumbinfo search
page = client.pages_getthumbinfo video_ids
items = page.info
p items.size
dir = Pathname(page.cache.filename_body).dirname + code
page.record.dir = dir.to_s
page.record.data = items
page.record.save

#- strip start-end time videos
items.delete_if{ |item| item['error'] }
items = items.select{ |item| start_time <= item['first_retrieve'] and item['first_retrieve'] < end_time }
items = items.sort_by{ |item|
      view    = item['view_counter']
      comment = item['comment_num']
      mylist  = item['mylist_counter']
      comment = view / 5.0 if comment * 5 > view
      mylist  = view * 8 / 25.0 if mylist * 25 > view * 8
      view    = mylist * 200 if view > mylist * 200
      view    = 0 if mylist == 0
      point   = (view + comment * 5 + mylist * 25).round
      item[:point] = point
      [point, item['view_counter'], item['comment_num'], item['mylist_counter'], item['video_id']] }.reverse
p items.size

#- cp to RankingFile.public_dir/:code
file = (end_time - 1).strftime "./public/day/#{code}/%Y%m%d.yml"
open(file, 'w'){ |f| f.write items.to_yaml }
$stderr.puts file

# or record = Salvage::Record.new
#    record.save??? [todo]
