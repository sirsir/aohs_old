class ComputerInfo < ActiveRecord::Base
  
  has_paper_trail
  
  belongs_to    :extension
  has_one       :current_computer_status, primary_key: :ip_address, foreign_key: :remote_ip
  
  validates   	:computer_name,
                presence: false,
                length: {
                  minimum: 3,
                  maximum: 100
                }

  validates_uniqueness_of :computer_name,
              allow_blank: false,
              allow_nil: false

  validates :ip_address,
              presence: false,
              format: {
                with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/, 
                message: "invalid ipv4 format"
              },
              length: {
                minimum: 7,
                maximum: 15
              }

  validates_uniqueness_of :ip_address,
              allow_blank: false,
              allow_nil: false                

end
