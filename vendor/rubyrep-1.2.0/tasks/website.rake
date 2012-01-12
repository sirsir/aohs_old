namespace :website do
  desc 'Generate website files'
  task :generate => :ruby_env do
    (Dir['website/**/*.txt'] - Dir['website/version*.txt']).each do |txt|
      sh %{ #{RUBY_APP} script/txt2html #{txt} > #{txt.gsub(/txt$/,'html')} }
    end
  end

  desc 'Upload website files to rubyforge'
  task :upload do
    host = "#{rubyforge_username}@rubyforge.org"
    remote_dir = "/var/www/gforge-projects/#{RUBYFORGE_PROJECT}/"
    local_dir = 'website'
    sh %{rsync -aCv #{local_dir}/ #{host}:#{remote_dir}}
  end

  desc 'Generate and upload website files'
  task :build => [:website_generate, :website_upload, :publish_docs]
end