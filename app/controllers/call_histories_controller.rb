class CallHistoriesController < ApplicationController
  
  before_action :authenticate_user!
  
  def index
    
    DisplayColumnTable.clear_field_cache
    
    paginate = {
      permin: Settings.pagination.voicelog.permin,
      permax: Settings.pagination.voicelog.permax
    }
    
    searchopts = {
      dayslimit: Settings.callsearch.max_period_days.to_i  
    }
    
    gon.push({
      paginate: paginate,
      searchopts: searchopts,
      qa_enable: qa_enable_mode,
      display_table: DisplayColumnTable.for(get_display_table).all,
      call_categories: CallCategory.not_deleted.map { |c| { id: c.id, code_name: c.code_name, title: c.title } },
      min_days_search: Settings.callsearch.scope_search_daterange
    })
    
    # key for search
    @key_params = {}
    
    # set cs-agent
    if params[:u].present?
      @int_agent = User.select([:id,:login,:full_name_th,:full_name_en]).where(id: params[:u]).first
      unless @int_agent.nil?
        @key_params[:agent_name] = @int_agent.display_name
      end
    end
    
    # set cs-group
    if params[:gr].present?
      @int_group = Group.select([:id,:short_name]).where(id: params[:gr]).first
      unless @int_group.empty?
        @key_params[:group_name] = @int_group.short_name
      end
    end
    
    # set cs-tags
    if params[:tag].present?
      @int_tag = Tag.where(id: params[:tag]).first      
    end

    # set cs-keyword
    if params[:kw].present?
      @int_keyword = Keyword.not_deleted.where(id: params[:kw]).first      
    end
    
    if params[:layout].present? and params[:layout] == 'blank'
      render layout: 'blank'  
    end
    
  end

  def list
    
    conds    = params[:search]
    paginate = params[:paginate]
    
    # added current_user_id
    conds[:current_user_id] = current_user.id
    
    cs = CallSearch.new(conds)
    
    result = cs.to_hash
    
    data = {
      voicelogs: result[:data],
      summary_info: result[:summary_info]
    }

    render json: data
    
  end
  
  def show
    
    begin
      gon.push({
        evaluation: {
          min_duration_sec: Settings.evaluation.min_duration_sec.to_i,
          close_window: Settings.evaluation.close_dialog
        },
        audioplayer: Settings.audioplayer
      })
    rescue
    end
    
    begin
      @voice_log = VoiceLog.where(id: voice_log_id).first
      @user      = @voice_log.user
      @user      = User.new if @user.nil?
      
      @left = {}
      @right = {}
      
      if @voice_log.call_direction == 'o'
        @left = {
          phone_no: @voice_log.ani,
          display_name: @user.display_name,
          ext_no: @voice_log.extension
        }
        @right = {
          phone_no: @voice_log.dnis
        }
      else
        @left = {
          phone_no: @voice_log.dnis,
          display_name: @user.display_name,
          ext_no: @voice_log.extension
        }
        @right = {
          phone_no: @voice_log.ani
        }
      end
      
      @task_filters = {
        call_direction: @voice_log.call_direction,
        call_duration: @voice_log.duration,
        call_date: @voice_log.start_time.to_date,
        user_id: current_user.id
      }
      
      render layout: 'blank' 
    rescue => e
      Rails.logger.error "No voice log found #{voice_log_id}, #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to controller: 'errors', action: 'no_content'
    end
  end

  private

  def get_display_table
    case params[:controller]
    when "call_histories"
      :call_history
    when "call_evaluation"
      :call_evaluation
    when "search"
      :text_search
    else
      :error
    end
  end
  
  def voice_log_id
    
    params[:id].to_i
    
  end
  
  def qa_enable_mode
    
    @qa_enable = false
    
    if params[:controller] == "call_evaluation" 
      @qa_enable = true
    end
    
    return @qa_enable
  
  end

end
