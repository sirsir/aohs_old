class DnisAgent < ActiveRecord::Base
  
  validates_presence_of     :dnis
  validates_presence_of     :ctilogin
  
end
