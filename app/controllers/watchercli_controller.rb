class WatchercliController < ApplicationController
  
  #layout LAYOUT_WATCHERCLI

  def index
  
  end

  def notification
    find_user

    render layout: LAYOUT_WATCHERCLI
		#@user = User.find_id(params[:id])
	end  

  def notification_history 

    output = {
      notifications: []
    }

    keyword = params[:keyword]
    login_name = params[:id]
    deln = nil
    max_result = 5

    usr = User.where(login: login_name).first
    unless usr.nil?
      deln = usr.user_attr("delinquent")
      unless deln.nil?
        deln = deln.attr_val
      end
    end

    begin
      s_words, m_words = AppUtils::TextPreprocessor.norm_text(keyword,:mysqlfulltext)
    rescue 
      s_words, m_words = nil, nil
    end

    faq_tags = FaqTag.where("match(tag_name) against (?)", s_words)
    if max_result > 0
      faq_tags = faq_tags.limit(max_result)
    end

    faq_questions = []
    faq_question_ids = faq_tags.all.map { |t| t.faq_question_id }    

    faq_question_ids.uniq.each do |faqid|
      faq_answers = FaqAnswer.where(faq_question_id: faqid)
      faq_question = FaqQuestion.where(id: faqid).first.question
      unless deln.nil?
        faq_answers = faq_answers.where("conditions LIKE ?", "%#{deln}%")
      end
      faq_answers = faq_answers.all.to_a
      unless faq_answers.empty?
        recommendations = (faq_answers.select {|x| x.content.to_s.length > 1 }).map { |a| a.content }
        recommendations = recommendations_to_html({ "question": faq_question , "answers": recommendations })

        output[:notifications] << {
          topic: "FAQ##{faqid}: " + faq_question,
          type: 'faq',
          body: recommendations,
        }
      end      
    end
    

    render json: output
  end

  def recommendations_to_html(recommendations)

    render_to_string template: "watchercli/notification_history", :layout => false, :formats=>[:html], :locals => {:recommendations => recommendations}

  end

  def history 
    find_user

    # input parameters
    # date = message date

    output = {
      notifications: []
    }

    output[:notifications] << {
      title: 'Found Improper Speech 1',
      level: 'warning',
      message: 'Do not talk like this with customer',
      recommendations: [
        { title: 'recommend case 1' },
        { title: 'recommend case 2' },
        { title: 'recommend case 3' }
      ],
      timestamp: Time.now.strftime.to_formatted_s(:web)
    }

    output[:notifications] << {
      title: 'Found Improper Speech 2',
      level: 'warning',
      message: 'Do not talk like this with customer',
      recommendations: [
        { title: 'recommend case 1' },
        { title: 'recommend case 2' },
        { title: 'recommend case 3' }
      ],
      timestamp: Time.now.strftime.to_formatted_s(:web)
    }

    render json: output
  end
  
  def log
    tnow = Time.now
    msg_id = params[:message_id]
    ref_id = params[:reference_id]
    c_ps = -1
    begin
      c_time = Time.parse(params[:ts])
      c_ps = (tnow.to_f - c_time.to_f).round(6)
    rescue
    end
    mlog = MessageLog.find_log(msg_id, ref_id).first
    unless mlog.nil?
      unless params[:item_id].blank?
        mlog.item_id = params[:item_id]
      end
      unless params[:comment].blank?
        mlog.comment = params[:comment]
      end
      if params[:read] == "true"
        mlog.set_read 
      end
      if params[:popup] == "yes"
        mlog.set_popup_desktop(params[:dsp_at])
        Rails.logger.info "(watchercli-mlog.dsp) [#{msg_id} - #{ref_id}] - displayed result to client at #{tnow.strftime("%Y-%m-%d %H:%M:%S.%5N")}. pstime=#{c_ps}"
      end
    else
      mlog = MessageLog.find_log(msg_id).first
      unless mlog.nil?
        if params[:popup] == "yes"
          mlog.set_popup_desktop(params[:dsp_at])
          Rails.logger.info "(watchercli-mlog.dsp) [#{msg_id} - #{ref_id}] - displayed result to client at #{tnow.strftime("%Y-%m-%d %H:%M:%S.%5N")}. pstime=#{c_ps}"
        end
      end
    end
    render text: "ok"
  end
  
  private

  def username
    params[:id]
  end

  def find_user
    @user = User.select([:id,:login]).where(login: username).first
  end

end
