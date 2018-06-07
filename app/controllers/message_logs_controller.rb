require 'csv'

class MessageLogsController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE

  def index
    page, per = current_or_default_perpage
    @message_logs = MessageLog.search(conditions_params).result
    @message_logs = @message_logs.order_by(order_params)
    @message_logs = @message_logs.page(page).per(per)
  end
  
  def download
    @message_logs = MessageLog.search(conditions_params).result
    @message_logs = @message_logs.order_by(order_params).limit(500)
    respond_to do |format|
      format.csv {
        data = []
        data << ["No","Message Type","Ext","Call Date/Time","Speech Time","Utt.EndTime","Recognize Time","Detected Time","Sent Time","Display Time","Ack. Time","Receiver","Detail"]
        @message_logs.each_with_index do |r,i|
          data << [row_no(i), r.log_type_name, r.voice_log_info.extension, r.call_start_time_t, r.speech_at_t, r.ut_ended_at_s, r.accepted_result_at_t, r.detected_result_at_dsp, r.created_at.to_formatted_s(:time), (r.display_at.nil? ? "" : r.display_at.to_formatted_s(:web)), r.acknowledge_date.nil? ? "" : r.acknowledge_date.to_formatted_s(:time), r.receiver_info.display_name,ActionController::Base.helpers.strip_tags(r.message_description.to_s)]
        end
        cdata = CSV.generate() do |csv|
          begin
            data.each { |item| csv << item.map { |f| f.to_s } }
          rescue => e
            Rails.logger.error e.message
          end
        end
        cookies['fileDownload'] = true
        send_data cdata, filename: "messagelogs.csv"
      }
    end
  end
  
  private

  def order_params   
    get_order_by(:created_at,:desc)
  end

  def conditions_params
    conds = {
      created_date_betw: get_param(:created_date),
      by_receiver: get_param(:receiver_name)
    }
    conds.remove_blank!
  end
  
end
