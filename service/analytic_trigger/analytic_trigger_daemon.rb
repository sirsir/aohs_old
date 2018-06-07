require 'daemons'

EXEC_FILE = File.join(File.dirname(__FILE__),'analytic_trigger.rb')
Daemons.run(EXEC_FILE)