# == Schema Information
# Schema version: 20100402074157
#
# Table name: extension_to_agent_maps
#
#  id        :integer(11)     not null, primary key
#  extension :string(20)
#  agent_id  :integer(10)
#

class ExtensionToAgentMap < ActiveRecord::Base
end
