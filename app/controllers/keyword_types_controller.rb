class KeywordTypesController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def update
    find_keyword_type
    
    @keyword_type.update_notification_setting(notification_params)
    if @keyword_type.save
      
    end
      
    redirect_to controller: 'keywords', action: 'keyword_type', id: keyword_type_id
  end
  
  def delete
    find_keyword_type
    render text: "deleted"
  end
  
  def destroy
    delete  
  end
  
  private
  
  def keyword_type_id
    params[:id]
  end
  
  def find_keyword_type
    @keyword_type = KeywordType.where(id: keyword_type_id).first
  end
    
  def notification_params
    data = params[:notify]
    data[:timeout] = data[:timeout].to_i
    unless data['title'].nil?
      data['title'] = Keyword.replace_tag(data['title'])
    end
    unless data['subject'].nil?
      data['subject'] = Keyword.replace_tag(data['subject'])
    end
    return data
  end
  
end
