require 'axlsx'

class CallTranscriptionReport
  
  def initialize(voice_log_id)
    
    @voice_log = VoiceLog.where({ id: voice_log_id }).first
    
  end
  
  def to_file  
  
    return to_xlsx

  end
  
  private
  
  def to_xlsx
    
    ds = trans_log
    
    p = Axlsx::Package.new
    w = p.workbook
    s = w.add_worksheet({name: "Transcription"})
    
    # style sheet
    
    styh1 = {
      b: true,
      bg_color: "4682B4",
      fg_color: "FFFFFF",
      border: Axlsx::STYLE_THIN_BORDER
    }
    styh1 = w.styles.add_style(styh1)
    
    styh2 = {
      bg_color: "4682B4",
      fg_color: "FFFFFF",
      border: Axlsx::STYLE_THIN_BORDER
    }
    styh2 = w.styles.add_style(styh2)    

    styh3 = {
      b: true,
      bg_color: "7EC0EE",
      fg_color: "FFFFFF",
      border: Axlsx::STYLE_THIN_BORDER
    }
    styh3 = w.styles.add_style(styh3)

    styh4 = {
      border: Axlsx::STYLE_THIN_BORDER
    }
    styh4 = w.styles.add_style(styh4)
    
    # header
    
    cols = ["Start Time", @voice_log.start_time.to_formatted_s(:web),nil]
    s.add_row cols, style: [styh1, styh2, styh2]
    s.merge_cells "B1:C1"
    
    cols = ["Agent's Name"]
    u = @voice_log.user
    unless u.nil?
      cols << u.display_name
    else
      cols << ""
    end
    cols << nil
    s.add_row cols, style: [styh1, styh2, styh2]
    s.merge_cells "B2:C2"
    
    cols = ["Time","Speaker","Result"]
    s.add_row cols, style: styh3

    ds.each do |r|
      s.add_row [r[:stime], r[:speaker], r[:text]], style: styh4    
    end
    
    fname = File.join(Settings.server.directory.tmp,"#{@voice_log.start_time.strftime("%Y%m%dT%H%M_#{@voice_log.extension}")}.xlsx")
    p.serialize(fname)
    
    return fname
  
  end
  
  def trans_log
    
    rs = []
    
    begin
      log = get_trans_log
      log.each do |l|
        rs << {
          stime: l[:stime], #StringFormat.format_sec(l.start_msec.to_i/1000.0),
          speaker: l[:type],
          text: l[:result]
        }
      end
    rescue => e
      Rails.logger.warn "No transcription log for id #{@voice_log.id}, #{e.message}"
    end
    
    return rs
  
  end
  
  def get_trans_log
    crrs = CallRecognitionResult.get_detail(@voice_log.id)
    trans = CallTranscription.parse_raw_result(crrs.transcriptions)
    #trans = CallRecognitionResult.get_transcriptions()
    #trans = CallTranscription.result_log(trans)
    return trans
  end
  
  def file_name
    
  end
  
end