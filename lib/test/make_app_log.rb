class MakeAppLog
  
  APPS = [
    { proc: "chrome", name: "Google Chrome", title: "google - Google Search" },
    { proc: "chrome", name: "Google Chrome", title: "AOHS" },
    { proc: "chrome", name: "Google Chrome", title: "CRM" },
    { proc: "explorer", name: "Windows Explorer", title: "My Computer" },
    { proc: "firefox", name: "Firefox", title: "Mozilla Firefox Start Page - Mozilla Firefox" },
    { proc: "excel", name: "Microsoft Excel", title: "Microsoft Excel - Book1" },
    { proc: "word", name: "Microsoft Word", title: "Microsoft Word - Document1" },
    { proc: "iexplore", name: "iexplore", title: "AmiVoice Data Storage - Internet Explorer" },
    { proc: "line", name: "LINE", title: "LINE" },
    { proc: "chrome", name: "Google Chrome", title: "Inbox - someone@gmail.com - Gmail - Google Chrome" },
    { proc: "line", name: "LINE", title: "LINE" },
    { proc: "", name: "IDLE_TIME", title: "IDLE_TIME" },
    { proc: "notepad++", name: "notepad++", title: "Notepad++" },
    { proc: "vlc", name: "vlc", title: "VLC media player" },
    { proc: "notepad", name: "notepad", title: "example.txt - Notepad" }
  ]
  
  def self.make_logs
    
    date = Date.today
    
    logs = VoiceLog.select("DISTINCT agent_id").at_date(date).all
    logs.each_with_index do |l,i|
      u = User.where(id: l.agent_id).first
      d1, d2 = u.id.divmod(254)
      STDOUT.puts "Creating log #{u.login} [#{i+1}/#{logs.length}]"
      stime = Time.parse(date.strftime("%Y-%m-%d 09:00:00"))
      while stime.hour <= 17
        app = APPS.sample
        duration = rand(45) + rand(15) + 1
        rec = {
          start_time: stime.strftime("%Y-%m-%d %H:%M:%S"),
          duration: duration,
          proc_name: app[:name],
          window_title: app[:title],
          login: u.login,
          user_id: u.id,
          remote_ip: "172.0.#{d1}.#{d2}",
          proc_exec_name: app[:proc]
        }
        ua = UserActivityLog.new(rec)
        ua.save
        stime = stime + duration
      end
    end
    
  end
  
end