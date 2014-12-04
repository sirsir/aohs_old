###########################################################################################################
# AOHS Variable
#
# This file contains any variables of system for running application and database schema
# First, Before setup application please set values for running environment.
# But if you set wrong value then may be occur error while running application
#
###########################################################################################################

module Aohs
  
  extend self
  
  ## Application Setting ##
  
  # start or stop service
  STOP_SERVICE                = false
  
  APP_PATH                    = Rails.root
  
  # run application customer site?
  CUSTOMER_SITE               = "aeon"                       
                              # [false,"acss","acsib","aeon"] 
  
  # web title and content's name
  WEB_TITLE_NAME              = "AmiVoice Operator's Help System"
  WEB_VERSION                 = "1.10"
  WEB_AUTHOR                  = "AmiVoice (Thailand)"
  WEB_CLOGO                   = CUSTOMER_SITE
                              # <name>_<report|login>.png             
  
  # web authentication #
  LOGIN_BY_AGENT              = false
  
  DEFAULT_PASSWORD            = "aohsweb!QAZ@WSX" # change password
  DEFAULT_PASSWORD_NEW        = "aohs*1234"       # all new account
  ADMIN_PASSWORD              = "AohsAdmin"       # admin account
  
  ALLOW_CHANGE_PASS_FRMSCR    = false
  
  # protected system accounts #
  PRIVATE_ACCOUNTS            = ['AohsAdmin']
  
  # Roles
  
  UNALLOWED_DELETE_ROLES      = ["Administrator","Agent"]  
  
  ## Voice Logger Setting ##
  # Logger env and voice_log table must be set before startup the application server 
  
  # current logger type 
  CURRENT_LOGGER_TYPE         = :extension        
                              # choose :extension or :eone
  EXTENSION_LOGGER_TRF        = true              
                              # extension logger and transfer call --> MOD_CALL_TRANSFER 
   
  # file checker and current running logger id
  LOGGER_ACTIVE_CHECKER_PATH  = "/opt/checker-1.0/active.conf"
  DEFAULT_LOGGER_ID           = 1
  LOGGERS_ID                  = []
                              # [1,2], [] 
  LOGGERS_LIST                = [
                                  {:id => 2, :name => "Sub", :url => "http://172.22.101.51:8081/AohsWeb"},
                                  {:id => 1, :name => "Main", :url => "http://172.22.101.40:8081/AohsWeb"}
                                ]
  VLTBL_PREFIX                = "voice_logs_"
  
  # call information
  CALL_EVENTS                 = { :transfer => 'Transfer', :hold => 'Hold' }
  
  ## Extension Lookup ##
  # for lookup and mapping data between agent and extension number 
  
  # agent mapping methods
  # CTI Toolbar mapping
  CTI_EXTENSION_LOOKUP        = true
  CTI_LOOKUP_BY_CTIID         = true
  CTI_LOOKUP_BY_USERN         = true
  CTI_LOGOUT_ENABLE           = false
  
  # Computer log mapping
  COMPUTER_EXTENSION_LOOKUP   = true
  COMP_LOOKUP_BY_KEYS         = [:comp_or_ip,:comp_and_ip,:comp,:ip][0]
  COMP_LOGOUT_ENABLE          = false
  COMP_RETRY_UPDATE	      = 0
  
  AUTO_CRTNEW_USR             = false
  DEFAULF_USERN_PATTERN       = "newAgent"
  
  
  ## voice log methods ##
  
  # call extensions summary and counting method
  VLOG_SUMMARY_BY             = [:normal_or_main,:inc_trf,:search_only][0]
  
  # check sometinh??
  PRMVL_CALLSEARCH_CHECK      = true
  
  # check call is part of my agent true = check
  PRMVL_CHECK_NOTIN_MY        = true  
  
  # number of days for periods <all>
  LIMIT_SEARCH_DAYS	      = 275
  
  # voice logs filter
  ENABLE_DEFAULT_VFILTER      = true
  VFILTER_DURATION_MIN	      = 1   # second
  
  ## schedulers ##
  
  SCHEDULE_ALL                = true
  SCHEDULE_PERMINT_RUN	      = SCHEDULE_ALL and true  
  SCHEDULE_PERHOUR_RUN	      = SCHEDULE_ALL and true
  SCHEDULE_DAILY_RUN	      = SCHEDULE_ALL and true
  SCHEDULE_WEEKLY_RUN         = SCHEDULE_ALL and true
  
  # schedule statistics data
  # RUNSTACALL_DAILY            = true   
  # RUNSTACALL_WEEKLY           = false
  # RUNSTACALL_MONTHLY          = false
  # RUNSTAKEYW_DAILY            = true
  # RUNSTAKEYW_WEEKLY           = false
  # RUNSTAKEYW_MONTHLY          = false

  RUNSTACALL_DAILY            = true   
  RUNSTACALL_WEEKLY           = false
  RUNSTACALL_MONTHLY          = true   
  RUNSTAKEYW_DAILY            = true
  RUNSTAKEYW_WEEKLY           = false
  RUNSTAKEYW_MONTHLY          = true   
  
  RUNST_PROCESS_TO_XDAY       = 0  			
                              # 0=today,1=yesterday
  RUNST_PROCESS_FROM_XDAY     = RUNST_PROCESS_TO_XDAY - 0
  
  WORKING_HR_PERIOD           = "8-20"
  
  # Maakit
  MAAKIT_TABLE_SRCLIST		  = 'tables.sync'
  MAAKIT_SYNCER_OPTION		  = :auto  # :auto, :same_server, :cross_server
  
  # delay day for repairing voice_log data
  NUMBER_OF_RECENT_DAY_FOR_RPVLC  = 2     
                                  # 0=today,1=yesterday,...
  NUMBER_OF_RECENT_DAY_FOR_RPSTC  = 2
  
  ## Report ##
  
  REPORT_USERTYPE_FILTER      = :none
                              # :agent , :manager, :none
  REPORT_ROLE_FILTER          = []
                              # ['Agent'] -> role name list

  ## Table Flags ##

  # for all table which use delete flag / or boolean
  FLAG_DELETE                 = 'd'
  
  
  ## Logs ##
   
  LOG_NAME                    = "AOHS"
  DAY_KEEP_LOGS               = 90
  DAY_KEEP_STATUS_LOG         = 15
  
  
  ## Constant ##
  
  UNKNOWN_AGENT_NAME          = ""
  CHR_TH                      = "กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮ๑๒๓๔๕๖๗๘๙๐"
  CHR_SARA_TH                 = "โไใเแ"
  CHR_EN                      = "abcdefghijklmnopqrstuvwxyz0123456789"
 

  DAYS_OF_THE_WEEK            = %w[mo tu we th fr sa su]
  WEEKS_PER_MONTH             = 4
  DAYS_PER_MONTH              = 30
  
  SITE_ROOT                   = "http://192.168.1.88:3003"
  APP_NAME                    = "AOHS"
  
  DEFAULT_DATETIME_FORMAT     = "%Y-%m-%d %H:%M:%S"
  DEFAULT_DATE_FORMAT         = "%Y-%m-%d"
  DEFAULT_TIME_FORMAT         = "%H:%M:%S"
  
  rpheaders                   = {:false => "AmiVoice Thai Co,.Ltd.", :aeon => "AEON Thana Sinsap (Thailand) Co., Ltd.", :acss => "ACS Servicing (Thailand) Co., Ltd.", :acsib => "ACS Insurance Broker (Thailand) Co., Ltd." }
  REPORT_HEADER_TITLE         = rpheaders[CUSTOMER_SITE.to_s.to_sym]
  
  MIMETYPE_CSV                = "application/csv"
  MIMETYPE_PDF                = "application/pdf"
  MIMETYPE_TXT                = "text/plain"
  
  DISPOSITION_PDF             = "attachment" 
  DISPOSITION_CSV             = "inline"  
  DISPOSITION_TXT             = "inline"  

  CALL_DIRECTION_CODES        = ['i', 'o', 'e']
  CALL_DIRECTION_COLORS       = { :i => '#00CC00', :o => '#316AC5', :e => '#0066CC', :u => '#993399' } 
  
  KEYWORDS_CODES              = ['n', 'm', 'a']
  KEYWORDS_COLORS             = { :n => '' , :m => '', :a => '' }
  
  # call timeline #
  CALL_TIMELINE_ONCUST        = false
  CALL_TIMELINE_ONCALL        = true
  
  TOOL_SHOW_TABLESINF         = true
  
  EXT_USE_LAST_FOUR_DIGITS    = true
  
  VALID_UNIQUE_CUSTNAME       = false
  
  USE_PHONE_PATTERN           = false
  
  SHOW_LOGGER_SWITCH          = true
  
  SHOW_TOTAL_ROW_AT_LAST_PAGE = true
  
  ## user tree
  
  ## Modules and Functions ##
  # enable/disable function
  
  MOD_CALL_BROWSER            = true
  
  MOD_DOWNLOAD_CALL           = false
  
  MOD_KEYWORDS                = true
  
  MOD_CUSTOMER_INFO           = false
  MOD_CUST_CAR_ID             = MOD_CUSTOMER_INFO  # acsib
  MOD_EDIT_CUST_ON_SEARCH     = true
  MOD_CUSTOMER_LOOKUP         = false
  
  MOD_CALL_TRANSFER           = true #EXTENSION_LOGGER_TRF
  
  ## Web Admin tool ##
  
  INSTALL_ADMIN_PATH          = "/opt/AohsWebTool"
  GLASSFISH_HOME              = "/opt/glassfishv3_cms/glassfish"
  
end

