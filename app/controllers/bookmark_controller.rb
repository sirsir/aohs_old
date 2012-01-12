class BookmarkController < ApplicationController

  before_filter :login_required

  def update

    begin

      @complete = false
      book_list = params[:list].split(/@/)

      book_list.each do |bl|
        data = bl.split(/,/)
        id = data[0].to_s

        if id != ""
          if CallBookmark.exists?(id)
            unless data[1] == 'delete'
              title = data[3].gsub(/"/,"")
              body  = data[4].gsub(/"/,"")
              if CallBookmark.update(data[0], { :start_msec => (data[1].to_f()*1000), :end_msec => (data[2].to_f()*1000),:title=>title,:body=>body})
                @complete = true
              else
                @complete = false
              end
            else
            CallBookmark.destroy(data[0])
          end
        else
          title = data[3].gsub(/"/,"")
          body  = data[4].gsub(/"/,"")
          @cbm = CallBookmark.new({:voice_log_id=> params[:voice_id],:start_msec => (data[1].to_f()*1000), :end_msec => (data[2].to_f()*1000),:title=>title,:body=>body})
          if @cbm.save
            @complete = true
          else
            @complete = false
          end
         end
        end

      end

      if @complete
        log("Update","CallBookmark",true,"voice_log:#{params[:voice_id]}")
      else
        log("Update","CallBookmark",false,"voice_log:#{params[:voice_id]}")
      end

      urls = url_for(:controller => 'voice_logs') + "/" + params[:voice_id]

      render :layout => false, :text => urls

   rescue

      log("Update","CallBookmark",false,"voice_log:#{params[:voice_id]}")

      render :layout => false, :text => ""

    end
    
  end

  def manage_bookmark

      begin

        unless params[:arrBookmark].empty?
          vl_id = 0
          params[:arrBookmark].each do |bookItem|
            bmd = bookItem.split(",")
            vl_id = bmd[1]
            STDERR.puts vl_id
            if CallBookmark.exists?(bmd[1])
               if bmd[4].to_s != "#remove#"
                  CallBookmark.update(bmd[1],
                                      {:start_msec => (bmd[2].to_f()*1000),:end_msec => (bmd[3].to_f()*1000),:title=>bmd[4].to_s,:body=>bmd[5].to_s})
               else
                #  STDERR.puts 'exists del'
                  CallBookmark.destroy(bmd[1].to_i)
               end
            else
             # STDERR.puts 'not exists'
              if bmd[4].to_s != "#remove#"
               # STDERR.puts 'not exists add'
                cb = CallBookmark.new(:voice_log_id =>bmd[0].to_i,
                                      :start_msec => bmd[2].to_f()*1000,
                                      :end_msec => bmd[3].to_f()*1000,
                                      :title => bmd[4].to_s(),
                                      :body => bmd[5].to_s());
                cb.save
              end
            end
          end

          log("Update","CallBookmark",true,"voice_log:#{vl_id}")
          render :text => 't'
        else
          log("Update","CallBookmark",false,"voice_log:#{vl_id}")
          render :text => 'f'
      end
      rescue => e
        log("Update","CallBookmark",false,"#{e.message}")
        render :text => 'f'
      end
  end

  # for 'voice_logs/shows/...' page
  def save_change_bookmark

    voice_log_id = params[:voice_log_id]
    bookmarks = params[:bookmarks] || []
    index = 0;

    db_bookmark = CallBookmark.find(:all, :conditions => {:voice_log_id => voice_log_id})
    db_bookmark.each do |currentBookmark|
      if not bookmarks[index].nil?
        bookmark_info = bookmarks[index].split(",")

        start_time = (bookmark_info[0].to_f)*1000
        end_time = (bookmark_info[1].to_f)*1000
        title = bookmark_info[2]
        body = bookmark_info[3]

        if currentBookmark.start_msec.to_f == start_time and
           currentBookmark.end_msec.to_f == end_time and
           currentBookmark.title == title and
           currentBookmark.body == body

          STDOUT.puts " -- Not Update bookmark id: #{currentBookmark.id}"
        else
          CallBookmark.update(currentBookmark.id, {:start_msec => start_time, :end_msec => end_time, :title => title, :body => body})
          STDOUT.puts " -- Update Bookmark :: "+currentBookmark.id.to_s+" to start_msec:"+start_time.to_s+" end_msec:"+end_time.to_s+" title:"+title+" body:"+body
        end

      else
        CallBookmark.destroy(currentBookmark.id)
        STDOUT.puts " -- Delete Bookmark :: "
      end
      index += 1
    end

    while index < bookmarks.length
      bookmark_info = bookmarks[index].split(",")

      start_time = (bookmark_info[0].to_f)*1000
      end_time = (bookmark_info[1].to_f)*1000
      title = bookmark_info[2]
      body = bookmark_info[3]

      new_bookmark = CallBookmark.new(:voice_log_id =>voice_log_id,
                                      :start_msec => start_time,
                                      :end_msec => end_time,
                                      :title => title,
                                      :body => body);

      if new_bookmark.save
        STDOUT.puts " -- New Bookmark :: start_msec:"+start_time.to_s+" end_msec:"+end_time.to_s+" title:"+title+" body:"+body
      else
        STDOUT.puts " -- Cannot Create Bookmark :: start_msec:"+start_time.to_s+" end_msec:"+end_time.to_s+" title:"+title+" body:"+body
      end

      index += 1
    end

    render :text => "Update bookmark complete."
  end

end
