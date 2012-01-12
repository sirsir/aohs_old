module Aohs
  
  extend self
  
  STOP_SERVICE          = false
  
  #
  # Web interface
  #
  
  WEB_TITLE_NAME        = "AmiVoice Operator's Help System"
  WEB_VERSION           = "1.0"
  WEB_AUTHOR            = "AmiVoice (Thai)"
  
  # Voice Logger
  
  LOGGER_ACTIVE_CHECKER_PATH  = "/opt/checker-1.0/active.conf"
  DEFAULT_LOGGER_ID           = 1
  LOGGERS_ID                  = [1,2]
    
  # LOG
  
  DAY_KEEP_LOGS               = 90
  
  #
  # Const
  #
  
  DAYS_OF_THE_WEEK      = %w[mo tu we th fr sa su]
  WEEKS_PER_MONTH       = 4
  
  SITE_ROOT             = "http://192.168.1.191:3008"
  APP_NAME              = "AOHS"
  DEFAULT_PASSWORD      = "aohs1234"
  DEFAULT_PASSWORD_NEW  = "aohsweb"
  
  REPORT_HEADER_TITLE   = "ACS Servicing (Thailand) Co,.Ltd." #"AmiVoice Thai Co,.Ltd."
  
  MIMETYPE_CSV          = "application/csv"
  MIMETYPE_PDF          = "application/pdf"
  MIMETYPE_TXT          = "text/plain"
  
  ## inline or attachment
  DISPOSITION_PDF       = "attachment" 
  DISPOSITION_CSV       = "inline"  
  DISPOSITION_TXT       = "inline"

  MOD_KEYWORDS          = true
  MOD_CALL_TRANSFER     = false

  VOICE_EXPORT_AUTH_URL	= "http://192.168.1.15:3000/sessions/new" #login=<id>
  
end
