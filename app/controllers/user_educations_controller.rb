class UserEducationsController < ApplicationController

  before_action :authenticate_user!

  layout LAYOUT_MAINTENANCE
  
  def create
    
    # remove existing
    if params[:edu_id].present?
      user_education = UserEducation.where(id: params[:edu_id]).first
      user_education.delete unless user_education.nil?
    end
    
    user_education = UserEducation.new(education_params)
    if user_education.save
      render json: user_education
    else
      render json: false
    end
    
  end

  def delete
    
    id = params[:id]
    
    education = UserEducation.where(user_id: user_id, id: id).first
    unless education.nil?
      education.delete
    end
    
    render json: { deleted: id }
    
  end
  
  def destroy
    delete
  end
  
  def list
    
    result = []
    educations = UserEducation.where(user_id: user_id).all
    
    educations.each_with_index do |edu,i|
      result << {
        id: edu.id,
        no: i+1,
        degree_id:    edu.degree,
        degree_title: edu.degree_title,
        institution:  edu.institution,
        subject:      edu.subject,
        year_passed:  edu.year_passed
      }
    end
  
    render json: result
    
  end

  private
  
  def user_id
    
    params[:user_id].to_i
    
  end
  
  def education_params
    
    return {
      user_id: params[:user_id],
      degree: params[:edu_degree],
      institution: params[:edu_inst],
      subject: params[:edu_subj],
      year_passed: params[:edu_year_passed]
    }
  
  end

end
