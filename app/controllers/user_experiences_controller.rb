class UserExperiencesController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE

  def create
    
    # remove existing
    if params[:exp_id].present?
      experience = UserExperience.where(id: params[:exp_id]).first
      experience.delete unless experience.nil?
    end
    
    experience = UserExperience.new(experience_params)
    if experience.save
      render json: experience
    else
      render json: false
    end
    
  end

  def delete
    
    id = params[:id]
    
    experience = UserExperience.where(user_id: user_id, id: id).first
    unless experience.nil?
      experience.delete
    end
    
    render json: { deleted: id }
    
  end
  
  def destroy
    delete
  end
  
  def list
    
    result = []
    experiences = UserExperience.where(user_id: user_id).all
    
    experiences.each_with_index do |exp,i|
      len_wrk = exp.length_of_work_in_ym
      result << {
        id: exp.id,
        no: i+1,
        position: exp.position,
        company: exp.company_name,
        length_of_work: exp.length_work,
        length_of_work_txt: exp.length_of_work_text,
        length_of_work_y: len_wrk[:years],
        length_of_work_m: len_wrk[:months],
        description: exp.description
      }
    end
  
    render json: result
    
  end

  private
  
  def user_id
    params[:user_id].to_i
  end
  
  def experience_params
    
    return {
      user_id: params[:user_id],
      position: params[:exp_position],
      company_name: params[:exp_company],
      length_work: params[:exp_length_of_work],
      description: params[:exp_description]
    }
  
  end

end
