require 'csv'
require 'yaml'

module DataSyncer
  module Aeon
    
    class AtlCallDataSyncer
      
      include SysLogger::ScriptLogger
      
      def self.sync
        acd = new
        
      end
      
      def initialize(options)
        set_logger_path "aeonatl/synccalldata.log"
        
      end
      
      def performance_sync
        
      end
      
    end
    
    # end module
  end
end
