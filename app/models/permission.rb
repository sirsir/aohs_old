# == Schema Information
# Schema version: 20100402074157
#
# Table name: permissions
#
#  id           :integer(11)     not null, primary key
#  role_id      :integer(10)
#  privilege_id :integer(10)
#  lock_version :integer(10)
#  created_at   :datetime
#  updated_at   :datetime
#

class Permission < ActiveRecord::Base
   belongs_to :privilege
   belongs_to :role

   def [] (key)
      if @role_hash.nil?
         @role_hash = Hash.new{ |h, k| h[k] = nil}
      end
      @role_hash[key]
   end

   def []=  (key, value)
      if @role_hash.nil?
         @role_hash = Hash.new{ |h, k| h[k] = nil}
      end
      @role_hash[key] = value
   end
end
