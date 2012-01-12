# == Schema Information
# Schema version: 20100402074157
#
# Table name: logs
#
#  id         :integer(11)     not null, primary key
#  start_time :datetime
#  name       :string(255)
#  status     :string(255)
#  target     :string(255)
#  user       :string(255)
#  remote_ip  :string(255)
#  message    :string(255)
#

class Logs < ActiveRecord::Base
  set_table_name('operation_logs')
end
