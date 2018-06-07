REPORT_LIB_ROOT = File.join(Rails.root,'lib','reports')

module ReportingTool
  
  REQUIRE_FILE = []
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'report_base')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'table_header')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'query')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluation_report_base')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'analytics_report_base')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'call_report_base')
  
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'agent_evaluation_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'agent_evaluation_detail')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'group_evaluation_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'evaluator_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'evaluator_call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'document_list')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'acs_greeting_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'acs_agent_call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'acs_ngusage_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'acs_call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'acs_evaluation_cnt')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'checking_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'checking_detail')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'evaluations', 'asst_detail_log')
  
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'analytics', 'asst_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'analytics', 'agent_keyword_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'analytics', 'noti_recommendation_agent_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'analytics', 'noti_keyword_agent_summary')
  
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'agent_call_usage')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'agent_call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'hourly_call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'agent_group_call_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'call_tag_summary')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'repeated_outbound_call_count')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'repeated_inbound_call_count')
  REQUIRE_FILE << File.join(REPORT_LIB_ROOT, 'calls', 'private_call_summary')
  
  REQUIRE_FILE.each do |rbfile|
    require rbfile
  end
  
  include EvaluationReport
  include AnalyticReport
  include CallStatisticsReport
  
  # end module
end