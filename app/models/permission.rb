class Permission < ActiveRecord::Base

  has_paper_trail
  
  belongs_to    :privilege
  belongs_to    :role
  
end
