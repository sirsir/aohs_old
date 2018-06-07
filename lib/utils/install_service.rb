require 'tilt'

module AppUtils
  class InstallService
    
    SVRC_DIRECTORY = "/etc/init.d"
    
    def self.install
      log "Installing service..."
      create_analytic_trigger
      log "Done."
    end
    
    private
    
    def self.create_analytic_trigger
      begin
        template = get_template('analytic_trigger.service.erb')
        args = {
          pg_file: File.join(Rails.root,'service/analytic_trigger/analytic_trigger_daemon.rb')
        }
        s_file = File.join(SVRC_DIRECTORY, 'aohs_analytic_trigger')
        File.open(s_file,'w') do |f|
          f.puts template.render("",args)
        end
        File.chmod 0755, s_file
        log "analytic trigger has bee installed."
      rescue => e
        log e.message
      end
    end
    
    def self.get_template(fname)
      return Tilt.new(File.join('lib/templates',fname))
    end
    
    def self.log(msg)
      STDOUT.puts "(service) #{msg}"  
    end
    
    # end class
  end
end