
module AmiTimeline

  def convert_bar_color_code(code,cd_colors)

    cd_color = nil

        case code
        when "i"
          cd_color = cd_colors[:i]
        when "o"
          cd_color = cd_colors[:o]
        when "u"
          cd_color = cd_colors[:u]
        when "e"
          cd_color = cd_colors[:e]
        else
          cd_color = cd_colors[:un]
        end
    return cd_color
    
  end

  def self.set_jnlp_file_and_js

    STDOUT.puts "=> Checking JavaFX resource and setting"

    begin
   
     svr_root = AmiConfig.get('client.aohs_web.serverRootUrl').to_s

     #AmiLog.linfo("[javafx-library-builder] - var aohs_web.serverRootUrl=#{svr_root}")
     #AmiLog.linfo("[javafx-library-builder] - var rails_root=#{RAILS_ROOT}")
     rpublic_path = Rails.public_path
     #AmiLog.linfo("[javafx-library-builder] - var public_path=#{rpublic_path}")

     #AmiLog.linfo("[javafx-library-builder] - writing resource to #{svr_root} ...")

     jfx_src = [
          {:src => 'javafx/dtfx-template.js', :dest => 'javafx/dtfx.js'},
          {:src => 'javafx/javafx-rt-template.jnlp', :dest => 'javafx/javafx-rt.jnlp'},
          {:src => 'javafx/amiTimeLine/amiTimeLine_browser-template.jnlp', :dest => 'javafx/amiTimeLine/amiTimeLine_browser.jnlp'},
          {:src => 'javafx/amiTimeLine/amiTimeLine-template.jnlp', :dest => 'javafx/amiTimeLine/amiTimeLine.jnlp'}
     ]
     
     STDOUT.puts "=> :: Updating source file"
       
     jfx_src.each do |s|

        STDOUT.puts "=> :: #{s[:src]} --> #{s[:dest]}"

        if File.exist?(File.join(rpublic_path,s[:src]))
          a = File.open(File.join(rpublic_path,s[:src])).read
          a = a.gsub("@SERVERROOT@",svr_root.gsub('http://',''))
          b = File.new(File.join(rpublic_path,s[:dest]),"w")
          b.puts(a)
          b.close
        else
          STDOUT.puts "=> :: #{s[:src]} not found"
        end

     end

    rescue => e
      AmiLog.lerror("[javafx-library-builder] - build file error : #{e.message}")
    end

  end
  
end