class CallTagsController < ApplicationController

  before_action :authenticate_user!
  
  protect_from_forgery :except => [:update_tags]
  
  def update_tags
    
    tags      = Tag.where(id: tags_id_params).all
    voice_log = VoiceLog.where(id: voice_log_id).first
    tags_id   = tags.map { |t| t.id }
    
    unless voice_log.nil?
      taggings  = voice_log.taggings.all
      taggings.each do |tg|
        unless tags_id.include?(tg.tag_id)
          tg.delete
        else
          tags_id.delete(tg.tag_id)
        end
      end
      
      unless tags_id.empty?
        tags_id.each do |t|
          tx = Tagging.new({ tag_id: t, tagged_id: voice_log.id })
          tx.save!
        end
      end      
    end
    
    render json: { success: true }
    
  end
  
  def list
    
    voice_log = VoiceLog.where(id: voice_log_id).first
    tags = Tag.where(id: voice_log.taggings.select(:tag_id))
    
    bs_tags   = []
    tag_names = []
    
    unless tags.empty?
      tags.each do |t|
        
        tag_names << t.name
        bs_tags   << {
          id: t.id,
          name: t.name
        }
        
      end
    end
    
    render json: {
      tags: tag_names,
      bs_tags: bs_tags
    }
    
  end
  
  private
  
  def tags_name_params
  
    params[:tags]
    
  end
  
  def tags_id_params
    
    params[:tags]
    
  end
  
  def voice_log_id
    
    params[:voice_log_id]
    
  end
  
end
