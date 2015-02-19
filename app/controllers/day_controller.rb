# coding: utf-8

require 'nico_salvage'

class DayController < ApplicationController
  before_action :basic_auth, only: [:edit, :fix, :conf, :pass, :editable]

  def top
  end

  def index
    @codes = RankingFile.rankings
  end

  def list
    setup_list
    @items.delete_if{ |item| item[:option] and item[:option]['state'] == 'delete' }
    respond_to do |format|
      format.html
      format.text {
        response.headers['Content-Type'] = 'text/tab-separated-values'
        tsv = Salvage::Record.new.hash2nrm @items
        tsv = tsv.map{ |line| line.join("\t") + "\n" }.join
        #tsv = tsv.encode('Shift_JIS') # encoding error [todo]
        render text: tsv
      }
    end
  end

  def edit
    setup_list
    @item_option = ItemOption.new
  end

  def update
    message = {session_id: session.id, message: "Session.#{session.id[0..5]}が編集作業を行いました"}
    WebsocketRails[:editors].trigger :websocket, message
    redirect_to action: :edit
  end

  def fix
  end

  def conf
    setup_conf
    text = params[:text]
    if text
      begin
        info = YAML::load(text)
        @rank.save_config info
        flash[:notice] = "config update"
      rescue
        flash[:error] = "yaml parse error"
      end
    end
  end

  def pass
    setup_conf
    @rank.password
    pass = params[:pass]
    if pass
      begin
        @rank.pass[:pass] = pass
        @rank.save_password 
        flash[:notice] = "password update"
      rescue
        flash[:error] = "password update error"
      end
    end
  end

  def bbs
    setup_conf
  end

  def editable
    code, day, video_id = params[:code], params[:date], params[:item]
    info = params[:undefined]

    rank = RankingFile.new code
    rank.day = day
    options = rank.options
    options[video_id] ||= {}
    options[video_id].update info
    rank.save_options options

    message = {session_id: session.id, message: "Session.#{session.id[0..5]}が編集作業を行いました"}
    WebsocketRails[:editors].trigger :websocket, message

    status = 'success'
    render json: {status: status}
  end

  private

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      rank = RankingFile.new params[:code]
      pass == rank.password[:pass]
    end
  end

  def setup_conf
    @code = params[:code]
    @day  = params[:date] || (Date::today - 1).strftime("%Y%m%d")
    params[:date] = @day

    rank = RankingFile.new @code
    rank.day = @day if @day
    @config = rank.config
    @items = rank.items
    @options = rank.options
    @rank = rank
  end

  def setup_list
    setup_conf

    @items.each{ |item|
      video_id = item['video_id']
      item[:option] = @options[video_id] if @options[video_id]
      if item[:option] and item[:option][:old_point]
        item[:org_point] = item[:point]
        item[:point] = item[:org_point] - item[:option][:old_point]
      end
    }
    @items = @items.sort_by{ |item| [item[:point], item['view_counter'], item['comment_num'], item['mylist_counter'], item['video_id']] }.reverse
  end
end
