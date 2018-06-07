class ManualController < ApplicationController

  before_action :authenticate_user!
  layout 'manual'
  
  def index
    render file: get_file(params[:tc])
  end
  
  private
  
  def get_file(code)
    File.open(get_db_file).each do |line|
      next if line =~ /^#/
      cx, fx = line.chomp.split(/ /)
      if cx == code
        return get_render_filename(fx) 
      end
    end
    return nil
  end
  
  def get_db_file
    return File.join(Rails.root,'lib/data/manual.list')
  end
  
  def get_render_filename(name)
    return "manual/" + name + ".html.slim"
  end

end
