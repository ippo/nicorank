class RankingFile #DailyRanking
  attr_accessor :code, :list, :opti, :conf, :pass
  attr_accessor :public_dir, :private_dir, :lock_dir
  attr_reader :day_str, :list_file, :opti_file
  @@public_base_dir  = "./public/day/"
  @@private_base_dir = "./private/day/"

  def self.rankings
    pass_files = Dir::glob("#{@@private_base_dir}/**.yml")
    pass_files.map{ |file|
      path = Pathname(file)
      path.basename.to_s.chomp path.extname
    }
  end

  def initialize ( config = {} )
    config = adjust_params config, :code
    @code = config[:code]
    @config ={
      public_dir:       "./public/day/#{@code}/",
      private_dir:      "./private/day/#{@code}",
      lock_dir:         "./private/day/#{@code}", # or false
      lock_out_time: 3                            # 3sec
    }
    @config.update config
    @public_dir    = Pathname @config[:public_dir]
    @private_dir   = Pathname @config[:private_dir]
    @lock_dir      = @config[:lock_dir]
    @lock_out_time = @config[:lock_out_time]
    @day           = @config[:today] || Date::today

    @day_str   = @day.strftime "%Y%m%d"
    @list_file = @public_dir + (@day_str + '.yml')
    @opti_file = @public_dir + (@day_str + '.opt')
    @conf_file = @public_dir.dirname + (public_dir.basename.to_s + '.yml')
    @pass_file = @private_dir.dirname + (private_dir.basename.to_s + '.yml')
    # @list = File::exist?(@list_file) ? load(@list_file) : []
    # @opti = File::exist?(@opti_file) ? load(@opti_file) : {}
    # @conf = load @conf_file
    # @pass = load @pass_file
  end

  def adjust_params ( params, key = :id )
    params = {key=>params} if params.class == String
    params
  end

  def load ( filename )
    data = nil
    lock{
      data = YAML::load_file filename
    }
    data
  end

  def save ( filename, info )
    # before_action? kick save message notation [todo]
    lock{
      open(filename, 'w'){ |f| f.write info.to_yaml }
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

  def items
    @list ||= File::exist?(@list_file) ? load(@list_file) : []
    @list
  end

  def options
    #@opti ||= File::exist?(@opti_file) ? load(@opti_file) : {}
    unless @opti
      if File::exist? @opti_file
        @opti = load @opti_file
      else
        @opti = {}
        copy_option
      end
    end
    @opti
  end

  def config
    @conf ||= File::exist?(@conf_file) ? load(@conf_file) : {}
    @conf
  end

  def password
    @pass ||= File::exist?(@pass_file) ? load(@pass_file) : {}
    @pass
  end

  def save_options ( params = @opti )
    save @opti_file, params
  end

  def save_config ( params = @conf )
    save @conf_file, params
  end

  def save_password ( params = @pass )
    save @pass_file, params
  end

  def day= ( day = Date::today )
    day = Date::parse day if day.class == String
    @day = day
    @day_str   = @day.strftime "%Y%m%d"
    @list_file = @public_dir + (@day_str + '.yml')
    @opti_file = @public_dir + (@day_str + '.opt')
    @day
  end

  def copy_option
    video_ids = items.map{ |item| item['video_id'] }
    options
    old_rank = RankingFile.new code: @code, today: (@day - 1)
    old_rank.options.each{ |video_id, old_option|
      next unless video_ids.include? video_id
      new_option = {}
      old_option.each{ |key, val|
        if key == 'state' and val == 'rankin'
          item = items.find{ |item| item['video_id'] == video_id }
          new_option[:old_point] = item[:point]
          memo = [new_option['memo']]
          new_option['memo'] = (memo + ["#{old_rank.day_str} rankin"]).join(',')
        elsif key == 'state' and val == 'pickup'
          memo = [new_option['memo']]
          new_option['memo'] = (memo + ["#{old_rank.day_str} pickup"]).join(',')
        else
          new_option[key] = val
        end
      }
      @opti[video_id] ||= {}
      @opti[video_id] = new_option.merge @opti[video_id]
    }
    save_options
  end

  #def merge_opti
  #  options = {}
  #  (@day - 7..@day).reverse.each{ |day|
  #    file = @public_dir + (day.strftime("%Y%m%d") + '.opt')
  #    info = File::exist?(file) ? load(file) : {}
  #    info.each{ |key, val|
  #      next if options[key]
  #      options[key] = val
  #    }
  #  }
  #  options
  #end
end
