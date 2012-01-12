class TagController < ApplicationController

  before_filter :login_required
  before_filter :permission_require, :except => [:manage, :update_tag]

  def new

  end

  def create

  end

  def edit

  end

  def update

  end

  def delete

  end

  def manage

    msg = "success"
    tag_action = ""
  
    voice_log_id = 0
    if params.has_key?(:voice_id) and not params[:voice_id].empty?
      voice_log_id = params[:voice_id].to_i   
    end

    case params[:tags_action]
      when "add"

         new_tag = params[:new_tags]
         vc = VoiceLogTemp.find(voice_log_id)
         tags = new_tag.split(',')
         tags.each do |tg|
          vc.tag_list.add(tg)
          vc.save
         end
         tag_action = "Add"

      when "remove"

         remove_tag = params[:new_tags]
         vc = VoiceLogTemp.find(voice_log_id)
         vc.tag_list.remove(remove_tag)
         vc.save
         tag_action = "Delete"

      when "remove_all"

         vc = VoiceLogTemp.find(voice_log_id)
         vc.tag_list.remove(vc.tag_list)
         vc.save
         tag_action = "Delete"
      
      when "update"

         new_tag = params[:new_tags]
         vc = VoiceLogTemp.find(voice_log_id)
         tags = new_tag.split(',')
         vc.tag_list.remove(vc.tag_list,:parse => true)
         tags.each do |tg|
            vc.tag_list.add(tg)
         end
         vc.save
         tag_action = "Update"
      
      when "show"

         vc = VoiceLogTemp.find(voice_log_id)
         msg = vc.tag_list
         if msg.blank?
           msg = "No Tag."
         end
         tag_action = "Show"
      
      else

    end

    log("#{tag_action}","CallTag",true,"voice_log:#{voice_log_id}, tag:#{params[:new_tags]}") unless tag_action == "Show"

    render :layout => false, :text => msg
    
  end

  # for 'voice_logs/shows/...' page
  def update_tag
    new_tag = params[:new_tags] || []
    del_tag = params[:del_tags] || []
    voice_log_id = params[:voice_id] if not params[:voice_id].empty?
    tag_action = ""

    # Begin : remove
    unless del_tag.empty?
      vc = VoiceLogTemp.find(voice_log_id)
      del_tag.each do |tg|
        vc.tag_list.remove(tg)
        vc.save
      end
      tag_action = "Delete"
    end
    # End : remove

    # Begin : add
    unless new_tag.empty?
      vc = VoiceLogTemp.find(voice_log_id)
      new_tag.each do |tg|
        vc.tag_list.add(tg)
        vc.save
      end
      tag_action = "Add"
    end

    log("#{tag_action}","CallTag",true,"voice_log:#{voice_log_id}") unless tag_action == "Show"

    render :layout => false, :text => "update tag."
  end
  
end
