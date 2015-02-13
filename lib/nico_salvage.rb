#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift './'
require 'salvage'

=begin
:index:
class NicoSalvage < Salvage
  class Access
  class Cache
  class Parse
  class Page
=end

class NicoSalvage < Salvage
end

class Salvage # NicoSalvage rename? [todo]
  NICO_VERSION = '0.2'

  class Access
    attr_reader :ext_uri, :flapi_uri, :upload_uri, :secure_uri

    def initialize_custom ( config = @config )
      @site_uri   = Pathname 'http://www.nicovideo.jp/'

      @ext_uri    = Pathname 'http://ext.nicovideo.jp/'
      @flapi_uri  = Pathname 'http://flapi.nicovideo.jp/'
      @upload_uri = Pathname 'http://www.upload.nicovideo.jp/'
      @secure_uri = Pathname 'http://secure.nicovideo.jp/'
    end

    def create_agent
      agent = Mechanize.new{ |mecha|
        mecha.max_history = 1
        mecha.user_agent = "NicoSalvage(ruby) v.#{Salvage::VERSION}+#{NICO_VERSION}"
      }
      agent.read_timeout = @config[:timeout] if @config[:timeout]
      agent
    end

    def set_params( params = nil )
      mode = @mode || :tag
      if params.class == Hash
        mode = params[:mode] if params[:mode]
        params = params.dup
        params.delete :mode
      end
      case mode
      when :tag; tag params
      when :tag_rss; tag_rss params
      when :getthumbinfo; getthumbinfo params
      end
    end

    # http://www.nicovideo.jp/tag/:keyword .html
    #   sort: nil/v/f/m/r/l <- comment-new/view/time/mylist/comment/length
    #   order: nil/a <- new/old large/small
    def tag ( params = {} )
      key = params
      if params.class == Hash
        hash = params.dup
        key = hash[:keyword]
        hash.delete :keyword
        params = hash
      else
        params = {}
      end
      @path = 'tag'
      @base_name = key.to_s
      @params = params
      @mode = :tag
      self
    end

    # http://www.nicovideo.jp/tag/:keyword?numbers=1&rss=2.0 .rss
    def tag_rss ( params = {} )
      params = {keyword: params} unless params.class == Hash
      params.update(numbers: 1, rss: '2.0')
      tag params
      @mode = :tag_rss
      self
    end

    # http://ext.nicovideo.jp/getthumbinfo/:video_id .xml
    def getthumbinfo ( params = {} )
      key = params
      if params.class == Hash
        hash = params.dup
        key = hash[:keyword]
        hash.delete :keyword
        params = hash
      else
        params = {}
      end
      @site_uri = @ext_uri
      @path = 'api/getthumbinfo'
      @base_name = key.to_s
      @params = params
      @mode = :getthumbinfo
      self
    end

    def over_word_count? ( keyword = nil ) # ??? check search word? ??? [todo]
      words = keyword.strip.split(/\s+/)
      words.delete_if{ |word| word =~ /^or$/i }
      return true if words.size > 32
      false
    end
  end

  class Cache
    def set_params ( params = nil )
      mode = @mode 
      if params.class == Hash
        mode = params[:mode] if params[:mode]
      end
      case mode
      when :tag_rss ; @ext_name = 'rss'
      when :getthumbinfo; @ext_name = 'xml'
      end
    end
  end

  class Parse
    attr_accessor :mode

    def decode ( data = @data )
      @data = data
      @info = xml2hash @data
      case @mode
      when :tag_rss
        @info = tag_rss @info
      when :getthumbinfo
        @info = getthumbinfo @info
      end
      @info
    end

    def tag_rss ( org_info = @info )
      info = {'item'=>[]}
      channel = org_info['channel'].first
      keys = channel.keys - ['item']
      keys.each{ |key|
        info[key] = channel[key].first
      }
      # key: <dc:creator>                  # ??? mylist-rss? ??? [todo]
      #if info['link'] =~ %r|mylist/(\d+)| # ??? mylist-rss? ??? [todo]
      #  info[:mylist_id] = $1
      #end
      channel['item'].each{ |org_item|
        item = {}
        org_item.keys.each{ |key|
          item[key] = org_item[key].first
        }
        item['pubDate'] = Time::parse item['pubDate']

        if item['link'] =~ %r|watch/([\w\d]+)|
            item[:video_id] = $1
        end
        desc = item['description']
        #<p class="nico-thumbnail">(.+?)</p>
        if desc =~ %r|<p class="nico-description">(.+?)</p>|mi
          item[:description] = $1
        end
        #<p class="nico-info">(.+?)</p>
        if desc =~ %r|<strong class="nico-info-length">(.+?)</strong>|
            item[:length] = $1
        end
        if desc =~ %r|<strong class="nico-info-date">(.+?)</strong>|
            item[:date] = $1
        end
        #<p class="nico-numbers">(.+?)</p>
        if desc =~ %r|<strong class="nico-numbers-view">(.+?)</strong>|
            item[:view] = $1.gsub(/\,/, '').to_i
        end
        if desc =~ %r|<strong class="nico-numbers-res">(.+?)</strong>|
            item[:res] = $1.gsub(/\,/, '').to_i
        end
        if desc =~ %r|<strong class="nico-numbers-mylist">(.+?)</strong>|
            item[:mylist] = $1.gsub(/\,/, '').to_i
        end
        info['item'] << item
      }
      @info = info
    end

    def getthumbinfo ( org_info = @info )
      single_keys = %w|video_id title description thumbnail_url first_retrieve length movie_type size_high size_low view_counter comment_num mylist_counter last_res_body watch_url thumb_type embeddable no_live_play user_id user_nickname user_icon_url ch_id ch_name ch_icon_url|
      #multi_keys = %w|tags|
      number_keys = %w|size_high size_low view_counter comment_num mylist_counter embeddable no_live_play user_id ch_id|
      #time_keys = %w|first_retrieve|
      info = {}
      if org_info['status'] == 'ok'
        thumb = org_info['thumb'].first
        thumb.each{ |key, val|
          if single_keys.include? key
            info[key] = val.first
            if number_keys.include? key
              info[key] = info[key].to_i
            end
            if key == 'first_retrieve'
              info[key] = Time::parse info[key]
            end
          elsif key == 'tags'
            tags = []
            thumb[key].each{ |c_tags|
              #c_tags['domain'] == 'jp' # 今はこれだけ 昔はtw,de,es
              tags += c_tags['tag'].map{ |tag| tag.class == String ? {'content'=>tag} : tag }
            }
            info[key] = tags
          end
        }
      elsif org_info['status'] == 'fail'
        info['error'] = org_info['error'].first
        info['error'].each{ |key, val| info['error'][key] = val.first }
      end
      @info = info
    end
  end

  class Record

    def load ( mode = @mode )
      message "#{self.class} : #{method_name(0)} : #{filename} ", DEVELOP_LEVEL
      lock{
        @data = case mode
                when :tsv  ; load_tsv
                when :json ; load_json
                when :nrm  ; load_nrm
                else       ; load_yaml
                end
      }
      @data
    end

    def save ( mode = @mode, data = @data )
      message "#{self.class} : #{method_name(0)} : #{filename} ", DEVELOP_LEVEL
      @data = data
      lock{
        check_and_create_dir filename.dirname
        case mode
        when :tsv  ; save_tsv
        when :json ; save_json
        when :nrm  ; save_nrm
        else       ; save_yaml
        end
      }
    end

    def nrm2hash ( lines = [] ) #??? [todo]
      info
    end

    def hash2nrm ( data = @data ) #??? [todo]
      list
    end

    def load_nrm #??? [todo]
      lines = []
      open(filename){ |f| lines = f.readlines }
      keys = lines.shift
      infos = []
      lines.each{ |line|
        info = {}
        keys.each_with_index{ |key, i| info[key] = line[i] }
        infos << info
      }
      @data = infos
    end

    def save_nrm #??? [todo]
      open(filename, 'w'){ |f|
        f.puts keys.join("\t")
        @data.each{ |line| f.puts line.values.join("\t") }
      }
    end
  end

  class Page
    attr_accessor :mode

    def set_params ( key = nil )
      # page.mode -> access,cache,parse,record.mode
      @access.mode = @cache.mode = @parse.mode = @record.mode = @mode
      @cache.label_dir = @mode

      # access.target_uri -> cache.filename -> record.filename
      if key
        @access.set_params key
        @cache.set_params key
      end
      if @cache_dir_mode == :uri
        @cache.uri  = @access.target_uri
      else
        @cache.base_name = @access.base_name + @access.params2query if @access.base_name
      end
      @record.dir = @cache.filename_body
    end
  end

  def page ( key = nil )
    new_page = Page.new
    new_page.agent = @agent
    mode = key
    params = {}
    params[:mode] = key if key
    if key.class == Hash
      mode = key[:mode]
      params = key
    end
    new_page.mode = mode if mode
    new_page.set_params params
    new_page
  end

  def pages_tag_rss ( params, limit_options )
    new_page = page :tag_rss
    items, page_number = [], 0

    limit       = limit_options[:limit]
    limit_key   = limit_options[:key]
    limit_order = limit_options[:order] # :gt :gq :lt :lq :eq

    limit_check_gt = lambda{ |val, limit| val >  limit }
    limit_check_gq = lambda{ |val, limit| val >= limit }
    limit_check_lt = lambda{ |val, limit| val <  limit }
    limit_check_lq = lambda{ |val, limit| val <= limit }
    limit_check_eq = lambda{ |val, limit| val == limit }
    limit_check = case limit_order
                  when :gt ; limit_check_gt
                  when :gq ; limit_check_gq
                  when :lt ; limit_check_lt
                  when :lq ; limit_check_lq
                  when :eq ; limit_check_eq
                  else ;     limit_check_gq
                  end

    begin
      page_number += 1
      page_info = new_page.get params.merge(page: page_number)
      page_items = page_info['item'].select{ |item| 
        # item[:date] # gt-time? from mechanize: country config?
        limit_check.call item[limit_key], limit
      }
      items += page_items
      #page.access.wait if page.access.get?
    end while page_items.size == page_info['item'].size
    new_page.info = items
    new_page
  end

  def pages_getthumbinfo ( video_ids = [] )
    new_page = page :getthumbinfo
    items = []

    video_ids.to_a.each{ |video_id|
      items << new_page.get(video_id)
      #page.access.wait if page.access.get?
    }
    new_page.info = items
    new_page
  end
end

#=begin
### Test Code / Examples ###
if __FILE__ == $0
  require 'pp'

=begin
  client = NicoSalvage.new
  p client.class
  p client.access.class
  client.access.create_agent
  p client.access.agent.user_agent
=end

=begin
  client = NicoSalvage.new
  client.access.tag 'vocaloid'
  p client.access.tag_rss 'vocaloid'
=end

=begin
  client = NicoSalvage.new
  page = client.page
  #infos = page.get mode: :tag_rss, keyword: 'utau'
  #pp infos
  page = client.page :tag_rss
  page.record_mode = true
  infos = page.get 'utau'
=end

=begin
  key = 'utau'
  client = NicoSalvage.new
  page = client.open :tag_rss
  info = page.get key
  p info.keys
  page.close
  client.open(:tag_rss){ |page|
    infos = page.get key
    p infos.keys
  }
  page = client.page mode: :tag_rss, keyword: key
  infos = page.get
  p page.data.size
  p infos.keys
=end

=begin
  client = NicoSalvage.new
  info = client.page(mode: :tag_rss, keyword: '初音ミク').get
  video_ids = info['item'].map{ |item| item[:video_id] }
  p video_ids
  p video_ids.size
  items = []
  page = client.page :getthumbinfo
  video_ids.each{ |video_id|
    items << page.get(video_id)
  }
  pp items.first
  p items.size
=end

=begin
  client = NicoSalvage.new
  page = client.page :tag_rss
  limit = Time.now - 2 * 24 * 60 * 60 # 3hour
  items, page_number = [], 0
  begin
    page_number += 1
    page_info = page.get(keyword: '初音ミク', sort: 'f', page: page_number)
    page_items = page_info['item'].select{ |item| 
      # item[:date] # gt-time? from mechanize: country config?
      item[:time] = Time::parse item['pubDate']
      limit <= item[:time]
    }
    items += page_items
    #page.access.wait if page.access.get?
  end while page_items.size == page_info['item'].size
  p page_number
  p items.size
=end
=begin
  #limit = Time.now - 2 * 24 * 60 * 60 # 3hour
  limit = Time::parse (Date::today - 7).to_s
  client = NicoSalvage.new
  params = {keyword: '初音ミク', sort: 'f'}
  limit_options = {limit: limit, key: 'pubDate'}
  page = client.pages_tag_rss params, limit_options
  items = page.info
  #p items.last
  p items.size
  dir = Pathname(page.cache.filename_body).dirname + params[:keyword]
  page.record.dir = dir.to_s
  page.record.data = items
  page.record.save

  video_ids = items.map{ |item| item[:video_id] }
  page = client.pages_getthumbinfo video_ids
  items = page.info
  #p items.last
  p items.size
  dir = Pathname(page.cache.filename_body).dirname + params[:keyword]
  page.record.dir = dir.to_s
  page.record.data = items
  page.record.save
=end
end
#=end

=begin
### ToDo / Refactoring ###
* test: Cache : search : cache_time = nil, first/last(before/after)
* test: Record : load/save json,tsv

* Record load_nrm save_nrm niconico-ranking-maker format
  * force_encode sjis ???

* 汎用性/再利用性/簡易性をあげようとして、むしろ複雑化/断片化/重複化/分散化している設計の修正
* 各class, methodの主客転置設計
  * default-paramsの定番メンバーとか、どっか設計がおかしいのでは
  * 例えば filename(@now_time) -> @now_time.filename
* class内classの継承: うまくできない
  class NicoSalvage < Salvage; end
  class NicoSalvage::Access < Salvage::Access; end
  Salvage.new.access #=> Salvage::Access
  NicoSalvage.new.access #=> Salvage::Access < NicoSalvage::Access にならない
  これがないとsuperを利用した手抜きができない
  多分それが一番欲しくなるだろうinitializeについてはdef initialize_customで暫定対応
* check tags domain="jp" only?
* ?: 元本データの名前: @data? @source? 何が適切?
=end
=begin
### XML 2 Hash ###
* XML解析と保存
* NokogiriでDOMする: データファイル保存には向いてなさそう
* Rails(ActiveSupport) Hash.from_xml(xml), XmlMini.parse(xml): かなり深くてごちゃい
* XmlSimple: 簡素 これを使ってみよう
  * 一番上の枠 root-tag は省略される(その中身がHashされる)
  * 各tagの内容はArray(複数回同tagが出る想定): array.first が結構必要
  * tagに属性がついている時はHash 'tag'=>{'attr1'=>val1, 'attr2'=>val2, 'content'=>value}
  * tagに属性がついてない時はString 'tag'=>value
  * だから中身を揃えたいのなら、if String then {'content'=>value} がいる
  * 具体的には getthumbinfo tags
=end
=begin
### Easy Ruby Sample ###

Rubyでニコニコ動画APIデータを取ってくるなら、簡単になら、

require 'open-uri'
require 'xmlsimple'
rss = open('http://www.nicovideo.jp/tag/vocaloid?rss=2.0')
info = XmlSimple.xml_in rss
open('info1.yml', 'w').write info.to_yaml
xml = open('http://ext.nicovideo.jp/api/getthumbinfo/sm1')
info = XmlSimple.xml_in xml
open('info2.yml', 'w').write info.to_yaml

と10行ぐらいでいい。

ただ、大量にやろうとすると、
* ちょくちょくネットが切れる。よくある。タイミングみて再取得。
* 検索時刻をフォルダ名にしながら繰返し取得。
* いつものテンプレート変換。
とかの機能が欲しくなる。
→ライブラリにする？
=end
