#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift './'

require 'pathname'
require 'time'
require 'uri'
require 'digest/sha2'

require 'json'
require 'yaml'

require 'mechanize'
require 'xmlsimple'

=begin
:index:
class Mechanize
class Time
module Tips
  module Message # エラーメッセージ
  module Adjust  # 色々小物
=end

DEBUG_LEVEL     = 0
DEVELOP_LEVEL   = 1
PRODUCTIN_LEVEL = 2
$message_level = DEVELOP_LEVEL
$message_code  = :utf8 # :sjis for windows

class Mechanize
  attr_accessor :logined # login/logout status : true/false or user_name/nil
end

class Time
  def fix ( step_sec = 10 * 60) # 10min # fixed, periodic, routine -time
    Time.at (self.to_i / step_sec) * step_sec
  end
  # Time.at(0) #=> 1970-01-01 09:00:00 +0900 # base is 9:00!(timezone)
  # then, if step_sec over 1hour, ex 2hour, and need 0,2,4-hour-clock,
  # hour9 = 9 * 60 * 60
  # Time.at ((self.to_i - hour9) / step_sec) * step_sec + hour9
end

module Tips
  module Message
    def message ( str = nil, level = nil, code = @message_code )
      return if level and @message_level and level < @message_level
      $stderr.puts message_encode(str)
    end

    def message_print ( str = nil, level = nil, code = @message_code )
      return if level and @message_level and level < @message_level
      $stderr.print message_encode(str)
    end

    def message_in ( options = nil )
      str = "#{self.class} : #{method_name} : in"
      str += " : #{message_options(options)}" if options
      message str, DEBUG_LEVEL
    end

    def message_out ( options = nil )
      str = "#{self.class} : #{method_name} : out"
      str += " : #{message_options(options)}" if options
      message str, DEBUG_LEVEL
    end

    def message_encode ( str = nil, code = @message_code )
      case code.to_s
      when 'utf8', 'utf-8';     str.encode('UTF-8')
      when 'euc',  'euc-jp';    str.encode('EUC-JP')
      when 'sjis', 'shift-jis'; str.encode('Shift_JIS')
      else ;                    str
      end
    end

    def message_options ( options = nil )
      if options
        if options.class == Hash
          return opt.map{ |key, val| "#{key}=#{val}" }.join(',')
        else
          return options.to_s
        end
      end
      ''
    end

    def method_name ( level = DEVELOP_LEVEL )
      /`(.+)'/.match(caller[level]).captures[0].to_sym rescue nil
    end

    def set_message_params
      # $message_code = :sjis if os == :windows
      @message_level = @config[:message_level] || $message_level
      @message_code  = @config[:message_code]  || $message_code
    end
  end

  module Adjust
    def adjust_params ( params, key = :id )
      params = {key=>params} if params.class == String
      params
    end

    def check_and_create_dir ( dir_name )
      dir_name = Pathname(dir_name) unless dir_name.class == Pathname
      unless File::exist? dir_name
        check_and_create_dir dir_name.dirname
        dir_name.mkdir
      end
    end

    def os
      platform = RUBY_PLATFORM.downcase
      #platform = RbConfig::CONFIG['host_os']
      #platform = RbConfig::CONFIG['target_os']
      if platform =~ /linux/
        return :linux
      elsif platform =~ /darwin/
        return :mac
      elsif platform =~ /mswin(?!ce)|mingw|cygwein|bccwin/
        return :windows
      end
      :unknown
    end
  end
end

=begin
:index:
class Salvage
  class Access  # ネット接続(get html)
  class Cache   # キャッシュ読書(read/write html)
  class Parse   # データ変換(html2hash)
  class Record  # データ読書(read/write hash)
  class Page    # まとめ(page.new = access,cache,parse,record .new)
=end

class Salvage
  VERSION = '0.2'

  class Access
    include Tips::Message
    include Tips::Adjust
    attr_accessor :agent, :site_uri, :uri
    attr_accessor :path, :base_name, :params # if create new-uri
    attr_accessor :method, :request_options  # post request body or something
    attr_accessor :data
    attr_accessor :mode
    
    class AccessError < StandardError; end

    def initialize ( config = {} )
      config = adjust_params config, :uri
      @config = {
        uri:            'https://news.google.co.jp/news',
        wait_time:      1,
        wait_long_time: 17,
        retry_count:    5
      }
      @config.update config
      @agent          = @config[:agent] || create_agent
      @retry_count    = @config[:retry_count]
      @wait_time      = @config[:wait_time]
      @wait_long_time = @config[:wait_long_time]
      @site_uri       = @config[:uri]
      @agent.logined  = false
      set_message_params
      initialize_custom @config
    end

    def initialize_custom ( config = @config )
    end

    def create_agent
      agent = Mechanize.new{ |mecha|
        mecha.max_history = 1
        mecha.user_agent = "Salvage(ruby) v.#{Salvage::VERSION}"
      }
      agent.read_timeout = @config[:timeout] if @config[:timeout]
      agent
    end

    def wait ( sec = @wait_time )
      message "wait #{sec}sec.", DEVELOP_LEVEL
      sleep sec
    end

    def wait_long ( sec = @wait_long_time )
      wait sec
    end

    def login ( user = nil, pass = nil )
      @agent.logined = true
    end

    def logout
      @agent.logined = false
    end

    def request_login
      login unless @agent.logined
    end

    def set_params ( key = nil )
      topic = case key
              when :headlines ;     :h
              when :world ;         :w
              when :business ;      :b
              when :technology ;    :t
              when :elections ;     :el
              when :politics ;      :p
              when :entertainment ; :e
              when :sports ;        :s
              when :health ;        :m
              else ;            key
              end
      @params = {topic: topic, output: :atom, ned: :us}
    end

    def target_uri
      @uri || Pathname(@site_uri) + @path.to_s + (@base_name.to_s + params2query(@params))
    end

    def get
      message_in
      uri = URI::escape target_uri.to_s
      message "#{self.class} : #{method_name(0)} : #{uri}", DEVELOP_LEVEL

      rescue_count = 0
      begin
        @page = @agent.get uri
      rescue SocketError, Timeout::Error, Errno::ETIMEDOUT, Mechanize::ResponseCodeError, AccessError => err
        rescue_count += 1
        message "#{err.class.to_s} が発生しました。待機して再度取得します。待機中。"
        wait_long
        if [Mechanize::ResponseCodeError, AccessError].include?  err.class
          message "もう少し待機中。(長め)(多分短時間連続アクセス制限なので解除狙いで)"
          wait_long
        end
        message "再度取得します。"
        retry if rescue_count < @retry_count
        message "数回繰り返しましたがエラーのままです。諦めます。"
        return false
      end
      message_out
      if @page
        @method = :get
        @data = @page.body
        return @data
      end
      nil
    end

    def params2query ( params = @params )
      str = ''
      if params
        hash = params.to_hash
        str = hash.keys.sort.map{ |key| "#{key}=#{hash[key]}" }.join('&')
      end
      str = '?' + str unless str.empty?
      str
    end
  end

  class Cache
    include Tips::Message
    include Tips::Adjust
    attr_accessor :uri, :method, :request_options # hard-address-dir mode
    attr_accessor :dir                            # easy-setting-dir mode
    attr_accessor :data
    attr_accessor :mode
    attr_accessor :lock_dir
    attr_accessor :now_time, :step_time, :offset_time, :cache_time # config
    attr_accessor :base_dir, :label_dir, :base_name, :ext_name     #
    attr_accessor :time_dir_format, :local                         #

    def initialize ( config = {} )
      config = adjust_params config, :base_dir
      @config ={
        base_dir:        './cache/',
        label_dir:       'label',
        base_name:       'data',
        ext_name:        'dat',
        time_dir_format: "./%Y/%m/%d/%H/%M/", # or false
        step_time:       60 * 30, # 30min # periodic/fixed time_dir
        offset_time:     0,       # 0sec
        cache_time:      60 * 60, # 1hour
        local:           :limit,  # or true or false
        lock_dir:        './lock', # or false
        lock_out_time:   3         # 3sec
      }
      @config.update config
      @base_dir        = Pathname @config[:base_dir]
      @label_dir       = @config[:label_dir]
      @base_name       = @config[:base_name]
      @ext_name        = @config[:ext_name]
      @time_dir_format = @config[:time_dir_format]
      @now_time        = @config[:now_time] || Time::now
      @step_time       = @config[:step_time]
      @offset_time     = @config[:offset_time]
      @local           = @config[:local]
      @cache_time      = @config[:cache_time] if @local != true
      @lock_dir        = @config[:lock_dir]
      @lock_out_time   = @config[:lock_out_time]
      set_message_params
      initialize_custom @config
    end

    def initialize_custom ( config = @config )
    end

    def load ( cache_filename = search )
      message "#{self.class} : #{method_name(0)} : #{cache_filename} ", DEVELOP_LEVEL
      lock{
        open(cache_filename, 'rb'){ |f| @data = f.read }
      }
      @data
    end

    def save ( data = @data )
      message "#{self.class} : #{method_name(0)} : #{filename} ", DEVELOP_LEVEL
      @data = data
      lock{
        check_and_create_dir filename.dirname
        open(filename, 'wb'){ |f| f.write @data }
      }
    end

    def lock
      timeout(@lock_out_time){
        if @lock_dir
          while Dir::mkdir(@lock_dir) != 0; end
          yield
          Dir::rmdir @lock_dir
        else
          yield
        end
      }
    end

    def exist?
      if !@local
        return false
      elsif @local == :limit
        return search
      else
        return search nil
      end
    end

    def search ( limit = @cache_time, step = @step_time )
      time = @now_time
      step = 1 * 60 if step.to_i == 0 # 1min
      if limit.nil?
        if step < 0 # before search
          @@first_cache_time ||= check_cache_time :first
          limit = @now_time.to_i - @@first_cache_time.to_i
        elsif step > 0 # after search
          @@last_cache_time ||= check_cache_time :last
          limit = @@last_cache_time.to_i - @now_time.to_i
        end
      end
      count = 1
      count += (limit / step.abs) if @time_dir_format
      count.times{ |i|
        cache_filename = filename(time)
        return cache_filename if File.exist? cache_filename
        time -= step
      }
      return false
    end

    def search_round ( limit = @cache_time, step = @step_time )
      name = search limit, step
      name = search limit, step * -1 unless name
      name
    end

    def check_cache_time ( way = :first )
      dirs = Dir::glob("#{@base_dir}/*").sort
      if way == :last
        dirs.last.ctime
      else
        dirs.first.ctime
      end
    end # or time_dir glob and sort first [todo]

    def filename ( time = @now_time )
      if @uri
        filename_uri(time)
      else
        filename_dir(time)
      end
    end
    
    def filename_uri ( time = @now_time )
      name = @base_dir + time_dir(time) + uri2filename
      
      if os == :windows or os == :mac
        uri_name = uri2filename
        dirname  = uri_name.dirname
        basename = uri_name.basename
        basename = basename.to_s.gsub(/\\|\/|\?|\:|\*|\"|>|<|\|/, '_') # error-char: \/?:*"><|
        name = @base_dir + time_dir + dirname + basename
      end
      
      if os == :windows
        limit_length = 260 # full-path-limit-length
        limit_length -= @ext_name.size + 1 if @ext_name
        if name.expand_path.to_s.bytesize > limit_length
          basename = basename2digest basename
          name = base_dir + time_dir + dirname + basename
        end
      end
      name = name.sub_ext('.' + @ext_name) if @ext_name
      name
    end

    def filename_dir ( time = @now_time )
      name = @base_dir + time_dir(time) + @label_dir.to_s + @base_name
      name = Pathname(name.to_s + '.' + @ext_name) if @ext_name
      name
    end

    def filename_body
      name = filename.to_s
      name.sub!(/^#{@base_dir}/, '')
      name.sub!(/#{filename.extname}$/, '')
      name
    end

    def time_dir ( time = @now_time )
      return '' unless @time_dir_format
      time = time.fix @step_time if @step_time
      time += @offset_time if @offset_time
      time.strftime @time_dir_format
    end

    def uri2filename ( uri = @uri, method = @method, request_options = @request_options, ext_name = @ext_name )
      method ||= 'get'
      uri = URI::parse uri.to_s
      scheme = uri.scheme
      host   = uri.host
      port   = uri.port
      path   = '.' + uri.path
      query  = uri.query
      name = Pathname(method) + scheme + host + port.to_s + path + query.to_s
      name += hash2filename(request_options)
      name
    end

    def basename2digest ( name )
      digest = Digest::SHA256.hexdigest name
      lock{
        check_and_create_dir @base_dir
      }
      file = @base_dir + 'basename.hash'
      hash_names = {}
      hash_names = YAML::load_file file if File::exist? file
      if hash_names[digest]
        if hash_names[digest] != name
          message "ERR!!! digest(hash) dup! : #{digest} : #{hash_names[digest]} | #{name}"
        end
     else
        hash_names[digest] = name
        open(file, 'w'){ |f| f.write hash_names.to_yaml }
      end
      digest
    end

    def hash2filename ( request_options = @request_options )
      str = ''
      if request_options
        hash = request_options.to_hash
        str = hash.keys.sort.map{ |key| "#{key}=#{hash[key]}" }.join('&')
      end
      str
    end
  end
  
  class Parse
    include Tips::Message
    include Tips::Adjust
    attr_reader :data, :info, :label
    attr_accessor :mode

    def initialize ( config = {} )
      config = adjust_params config, :label
      @config ={}
      @config.update config
      set_message_params
      initialize_custom @config
    end

    def initialize_custom ( config = @config )
    end

    def decode ( data = @data )
      @data = data
      @info = xml2hash @data
    end

    def xml2hash ( data = @data )
      info = XmlSimple.xml_in data
    end
  end

  class Record
    include Tips::Message
    include Tips::Adjust
    attr_accessor :base_dir
    attr_accessor :dir
    attr_accessor :data
    attr_accessor :mode

    def initialize ( config = {} )
      config = adjust_params config, :base_dir
      @config ={
        base_dir:        './info/',
        mode:            :yaml,
        ext_name:        'yml',
        lock_dir:        './lock', # or false
        lock_out_time:   3         # 3sec
      }
      @config.update config
      @base_dir      = Pathname @config[:base_dir]
      @ext_name      = @config[:ext_name]
      @lock_dir      = @config[:lock_dir]
      @lock_out_time = @config[:lock_out_time]
      set_message_params
      initialize_custom @config
    end

    def initialize_custom ( config = @config )
    end

    def load ( mode = @mode )
      message "#{self.class} : #{method_name(0)} : #{filename} ", DEVELOP_LEVEL
      lock{
        @data = case mode
                when :tsv  ; load_tsv
                when :json ; load_json
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
        else       ; save_yaml
        end
      }
    end

    def lock
      timeout(@lock_out_time){
        if @lock_dir
          while Dir::mkdir(@lock_dir) != 0; end
          yield
          Dir::rmdir @lock_dir
        else
          yield
        end
      }
    end

    def exist?
      File::exist? filename
    end

    def filename
      name = @base_dir + (@dir + '.' + @ext_name)
      name
    end

    def load_tsv
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

    def save_tsv
      open(filename, 'w'){ |f|
        f.puts keys.join("\t")
        @data.each{ |line| f.puts line.values.join("\t") }
      }
    end

    def load_json
      open(filename){ |f| @data = JSON.load f }
    end

    def save_json
      open(filename, 'w'){ |f| JSON.dump @data, f }
    end

    def load_yaml
      @data = YAML::load_file filename
    end

    def save_yaml
      open(filename, 'w'){ |f| f.write @data.to_yaml }
    end
  end

  class Page
    include Tips::Message
    include Tips::Adjust
    attr_reader :data
    attr_accessor :info
    attr_accessor :mode
    attr_accessor :access, :cache, :parse, :record
    attr_accessor :record_mode, :cache_dir_mode

    def initialize ( config = {} )
      @config ={
        record_mode: false # true/:on/:save
      }
      @config.update config
      @access = Access.new @config
      @cache  = Cache.new @config
      @parse  = Parse.new @config
      @record = Record.new @config
      set_message_params
      initialize_custom @config
    end

    def initialize_custom ( config = @config )
    end

    def agent
      @access.agent
    end

    def agent= ( new_agent ) # cannot delegate:agent is attr, not method. [note]
      @access.agent = new_agent
    end

    def set_params ( key = nil )
      # access.target_uri -> cache.filename -> record.filename
      @access.set_params key if key
      @cache.uri  = @access.target_uri if @cache_dir_mode == :uri
      @record.dir = @cache.filename_body
    end

    def get ( key = nil )
      set_params key
      unless @record.exist?
        unless @cache.exist?
          @cache.data = @access.get
          @cache.save
        else
          @cache.load
        end
        @record.data = @parse.decode @cache.data
        @record.save if @record_mode
      else
        @record.load
      end
      @data = @cache.data
      @info = @record.data
      @info
    end

    def close
    end
  end

  include Tips::Message
  include Tips::Adjust
  attr_accessor :access, :cache, :parse
  attr_accessor :agent

  def initialize ( config = {} )
    message "#{self.class} : #{method_name(0)} : #{Time.now}", DEVELOP_LEVEL
    config = adjust_params config, :id
    @config = {}
    @config.update config
    @access = Access.new @config
    @agent = @access.agent
    set_message_params
  end

  def login ( user, pass )
    @access.login user, pass
  end

  def logout
    @access.logout
  end

  def page ( key = nil )
    new_page = Page.new
    new_page.agent = @agent
    new_page.access.base_name = key
    new_page
  end

  def open ( key = nil )
    new_page = page key
    yield new_page if block_given?
    new_page
  end

  def close
  end
end

#=begin
### Test Code / Examples ###
if __FILE__ == $0
  require 'pp'

=begin
  access = Salvage::Access.new
  p access.get.size
  access.basename = 'section'
  access.params = {topic: 't', output: 'atom', ned: 'us'}
  pp access.get
=end
  
=begin
  cache = Salvage::Cache.new
  p cache.filename
  cache.uri = 'http://www.google.co.jp/search?q=test'
  p cache.filename
  cache.uri = URI::escape 'http://www.google.co.jp/search?q=てすと'
  p cache.filename
  cache.step_time = nil
  cache.uri = URI::escape 'http://www.google.co.jp/search?q=てすと'
  p cache.filename
  cache.uri = URI::escape 'http://www.google.co.jp/search?q=' + 'a' * 300
  p cache.filename
=end

=begin
  client = Salvage.new
  client.login 'user', 'pass'
  page = client.page
  page.access.params = {topic: 't', output: 'atom', ned: 'us'}
  page.record_mode = true
  page.cache_dir_mode = false
  infos = page.get
  client.logout
  #pp infos
  p infos.class

  page = client.page :section
  page.record_mode = false
  page.cache_dir_mode = :uri
  infos = page.get :technology
  #pp infos
  p infos.class
=end
end
#=end
