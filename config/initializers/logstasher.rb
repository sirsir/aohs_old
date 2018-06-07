
# log stasger setting

if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    
    # This block is run in application_controller context,
    # so you have access to all controller methods
    fields[:user] = current_user && current_user.login

    # If you are using custom instrumentation, just add it to logstasher custom fields
    # LogStasher.custom_fields << :myapi_runtime
  end
end