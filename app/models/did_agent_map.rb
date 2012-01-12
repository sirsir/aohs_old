# == Schema Information
# Schema version: 20100402074157
#
# Table name: did_agent_maps
#
#  id       :integer(11)     not null, primary key
#  number   :string(20)
#  agent_id :integer(10)
#

class DidAgentMap < ActiveRecord::Base
end
