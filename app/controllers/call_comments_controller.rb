class CallCommentsController < ApplicationController
  
  before_action :authenticate_user!
  
  protect_from_forgery :except => [:update_comment, :delete_comment]

  def update_comment
    
    ccm     = nil
    comment = comment_params
    result  = {
      success:  false
    }
    
    if comment[:id] >= 0
      ccm = CallComment.where(id: comment[:id], voice_log_id: voice_log_id).first
    end
    
    if ccm.nil?
      cmm = CallComment.new({ voice_log_id: voice_log_id });
    end
    
    unless comment[:comment].empty?
      cmm.created_by = current_user.id
      cmm.comment    = comment[:comment]
      cmm.flag       = ""
      if cmm.save
        result[:success] = true
      end
    end
    
    render json: result
    
  end
  
  def delete_comment
    
    comment_id = params[:id]
    ccm = CallComment.where(id: comment_id, voice_log_id: voice_log_id).first
    
    unless ccm.nil?
      ccm.do_delete
      ccm.save
    end
    
    render json: { success: true }
    
  end
  
  def list
    
    comments = []
    
    ccm = CallComment.not_deleted.where(voice_log_id: voice_log_id).order(:created_at).all
    
    unless ccm.empty?
      ccm.each do |cm|
        comments << {
          id: cm.id,
          ctime: cm.created_at.to_formatted_s(:web),
          comment_by: cm.user.display_name,
          details: cm.comment.to_s,
          disabled: ((cm.created_by == current_user.id) ? "" : "_disabled")
        }
      end
    end
    
    render json: {
      comments: comments
    } 
  
  end
  
  private
  
  def comment_params
    
    return {
      id: params[:id].to_i,
      comment: params[:comment].to_s
    }
    
  end
  
  def voice_log_id
    
    params[:voice_log_id].to_i
    
  end
  
end
