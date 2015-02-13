
#day_controller
class RankingFile #DailyRanking
  attr_accessor :code, :list, :opti, :conf, :pass
  attr_accessor :public_dir, :private_dir, :lock_dir

  def initialize ( config = {} )
    config = adjust_params config, :code
    @code = config[:code]
    @config ={
      public_dir:    "./public/day/#{@code}/",
      private_dir:   "./private/day/#{@code}/",
      lock_dir:      "./private/day/#{@code}/lock", # or false
      lock_out_time: 3                          # 3sec
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

  def load ( filename )
    lock{
      YAML::load_file filename
    }
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

  def merge_opti
    options = {}
    (@day - 7..@day).reverse.each{ |day|
      file = @public_dir + (day.strftime("%Y%m%d") + '.opt')
      info = File::exist?(file) ? load(file) : {}
      info.each{ |key, val|
        next if options[key]
        options[key] = val
      }
    }
    options
  end
end
