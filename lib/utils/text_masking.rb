module AppUtils
  class TextMasking
    
    REPLACEMENT_CHAR = "X"
    SEPARATOR = "\n"
    MASKING_FILE = File.join(Rails.root,'lib','data','masking.json')
    
    def self.masking_conversation(convers)
      tm = new(convers)
      return tm.mask
    end
    
    def initialize(convers)
      @convers = convers
      if not defined_rule? and rule_file_exist?
        load_masking
      end
    end
    
    def mask
      
      begin
        if @convers and not @convers.empty?

          log :info, "masking transcription"

          set_org_convers
          
          # mask by first join all talk then focus on long digits
          # do_mask2

          # mask by context
          # do_mask

          # (studio) mask by first join all talk (same channel) then focus on long digits
          do_mask3

          restore_unmask_convers

          return @convers
        else
          return []
        end
      rescue => e
        log :error, e.message
        log :error, e.backtrace
      end
      return @org_convers
            
    end


    
    private

    def set_org_convers

      key = :result
      key2 = :org_result
      if not @convers[0][key]
        key = "result"
        key2 = "org_result"
      end

      @org_convers = @convers.map do |cv|
        {
          org_result: cv[key2],
          result: cv[key]
        }
      end

    end

    
    def log(type, msg, debug=1)
      case type
      when :error
        Rails.logger.error "(masking) #{msg}"
      when :debug
        if debug == 1
          Rails.logger.debug "(masking) #{msg}"
        else
          Rails.logger.debug "(masking) #{msg}" 
        end
        
      else
        Rails.logger.info "(masking) #{msg}"
      end
    end

    def defined_rule?
      return (defined? $MASK_RULES)
    end


    def rule_file_exist?
      return File.exist?(MASKING_FILE)
    end

    def get_masking_source
      return JSON.parse(File.read(MASKING_FILE))
    end

    def load_masking
      jsdata = get_masking_source

      tmp_rule = {}
      tmp_rule[:topics_str] = jsdata["topics_to_mask"]
      tmp_rule[:topics_must_not_str] = jsdata["topics_to_mask_must_not_include"]
      tmp_rule[:topics_not_str] = jsdata["topics_not_to_mask"]
      tmp_rule[:units_str] = jsdata["units"]
      tmp_rule[:normalized_table] = jsdata["normalized_number"]
      tmp_rule[:normalized_number_post_replace] = jsdata["normalized_number_post_replace"]

      tmp_rule[:no_num_count_max] = jsdata["reset_topic_no_num_limit"]
      
      tmp_rule[:number_cloud_not_follow] = jsdata["config_mask_group_of_num"]["string_not_allowed_before_group_of_number"].split("/").map{  |str| "(?<!#{str})(?<!#{str} )"}.join
      tmp_rule[:number_cloud_regexp] = Regexp.new tmp_rule[:number_cloud_not_follow]+"(\\d|"+jsdata["config_mask_group_of_num"]["string_allowed_in_group_of_number_english"].gsub("/","|")+")(\\d| |" +jsdata["config_mask_group_of_num"]["string_allowed_in_group_of_number"].gsub("/","|")+"|"+jsdata["config_mask_group_of_num"]["string_allowed_in_group_of_number_english"].gsub("/","|")+")+\\d" , Regexp::IGNORECASE | Regexp::MULTILINE
      tmp_rule[:english_regexp] = Regexp.new jsdata["config_mask_group_of_num"]["string_allowed_in_group_of_number_english"].gsub("/","|"), Regexp::IGNORECASE | Regexp::MULTILINE
      
      tmp_rule[:nomask_leading_pattern] = Regexp.new jsdata["config_mask_group_of_num"]["nomask_leading_pattern"].gsub("/","|") , Regexp::IGNORECASE | Regexp::MULTILINE
      tmp_rule[:nomask_leading_pattern_exclude] = Regexp.new jsdata["config_mask_group_of_num"]["nomask_leading_pattern_exclude"].gsub("/","|") , Regexp::IGNORECASE | Regexp::MULTILINE
      
      tmp_rule[:nomask_tailing_pattern] = Regexp.new jsdata["config_mask_group_of_num"]["nomask_tailing_pattern"].gsub("/","|") , Regexp::IGNORECASE | Regexp::MULTILINE
      
      tmp_rule[:topics_str].select! {|str| str[0].downcase != "x"}
      tmp_rule[:topics_must_not_str].select! {|str| str[0].downcase != "x"}
      tmp_rule[:topics_not_str].select! {|str| str[0].downcase != "x"}
      
      tmp_rule[:normalized_number_post_replace].map! do |pair|
        newpair = pair.clone

        newpair[0] = Regexp.new newpair[0]

        newpair
      end

      tmp_rule[:topics_reg_array] = create_regexp(tmp_rule[:topics_str])
      tmp_rule[:topics_must_not_reg_array] = create_regexp(tmp_rule[:topics_must_not_str])
      tmp_rule[:topics_not_reg_array] = create_regexp(tmp_rule[:topics_not_str])
      
      tmp_rule[:topics_all] = Regexp.union (tmp_rule[:topics_reg_array] + tmp_rule[:topics_not_reg_array])
      tmp_rule[:topics]= Regexp.union tmp_rule[:topics_reg_array]
      tmp_rule[:topics_not]= Regexp.union tmp_rule[:topics_not_reg_array]
      
      tmp_rule[:topics_must_not] = Regexp.union tmp_rule[:topics_must_not_reg_array]
      
      tmp_rule[:units_str_max_length] = tmp_rule[:units_str].map{|u| u.length}.max
      tmp_rule[:units_reg_array] = create_regexp(tmp_rule[:units_str])
      tmp_rule[:units] = Regexp.union tmp_rule[:units_reg_array]
      
      tmp_rule[:hash_from_normalized_table] = {}
      tmp_rule[:normalized_table].each do |obj|
        
        obj["words"].each do |w|
          tmp_rule[:hash_from_normalized_table][w] = obj["normalized"]
        end
        
      end
      
      $MASK_RULES = tmp_rule
    end


    def create_regexp(o_ary)

      return o_ary.map { |str|
        Regexp.new(str, Regexp::IGNORECASE | Regexp::MULTILINE)
      }

    end


    def do_mask
      do_mask_for_field_result
      do_mask_for_field_org_result
    end

    def do_mask2
      do_mask2_for_field_result
      do_mask2_for_field_org_result
    end

    def do_mask3
      do_mask3_for_field_result
      do_mask3_for_field_org_result
    end


    def do_mask_for_field_org_result
      swap_key
      do_mask_for_field_result
      swap_key_inv
    end


    def restore_unmask_convers
      key = :result
      key2 = :org_result
      if not @convers[0][key]
        key = "result"
        key2 = "org_result"
      end
      # key_backup = :backup_key

      @convers.map!.with_index do |cv,idx|

        unless cv[key].include? REPLACEMENT_CHAR
          # log :debug, "restore talk"
          # log :debug, cv[key]
          # log :debug, @org_convers[idx][key]

          cv[key] = @org_convers[idx][key]
        end
        unless cv[key2].include? REPLACEMENT_CHAR
          cv[key2] = @org_convers[idx][key2]
        end

        cv
      end
    end

    def swap_key
      key = :result
      key2 = :org_result
      if not @convers[0][key]
        key = "result"
        key2 = "org_result"
      end
      key_backup = :backup_key

      @convers.map! do |cv|
        cv[:backup_key] = cv[key]

        cv[key] = cv[key2]

        cv
      end

    end

    def swap_key_inv
      key = :result
      key2 = :org_result
      if not @convers[0][key]
        key = "result"
        key2 = "org_result"
      end
      key_backup = :backup_key

      @convers.map! do |cv|

        cv[key2] = cv[key]
        cv[key] = cv[:backup_key] 

        cv
      end

    end

    def get_only_key(str_in,obj_in)
      obj_in.map{|e| 
         e[str_in]
      }.join("\n")
      

    end

    def do_mask2_for_field_result
      # log :debug, ":result before domask2", 1
      # log :debug, get_only_key(:result, @convers), 1


      convers_results = @convers.map do |cv|
        if not cv[:result]
          cv[:result] = cv["result"]
        end
        
        " " + cv[:result] + " "
      end

      convers_results_new = do_mask2_for_obj(convers_results)

      @convers.each_index do |idx|
        @convers[idx][:result]= convers_results_new[idx]
      end

      # log :debug, ":result of domask2"
      # log :debug, get_only_key(:result, @convers)

    end

    def do_mask3_for_field_result
      # log :debug, ":result before domask2", 1
      # log :debug, get_only_key(:result, @convers), 1

      @convers_mapping = {}

      @convers_by_channel = [get_convers_array("A") , get_convers_array("C")]

      convers_results_new = @convers_by_channel.map.with_index do |cr,idx|
        do_mask3_for_obj(cr,idx)
      end

      set_convers_from_array(convers_results_new)

      # log :debug, ":result of domask3"
      # log :debug, get_only_key(:result, @convers)

    end

    def do_mask3_for_field_org_result
      swap_key
      do_mask3_for_field_result
      swap_key_inv

    end

    def set_convers_from_array(convers_array)
      # log :debug, ":input to set_convers_from_array", 1
      # log :debug, convers_array, 1

      @convers.each_index do |idx|

        convers_array_idx = @convers_mapping[idx] == "A"? 0:1

        @convers[idx][:result] = convers_array[convers_array_idx][idx]

        @convers[idx][:result] = "" if @convers[idx][:result].nil?

        @convers[idx][:result].gsub!(/^<.*?>/,"")
   
      end

      # log :debug, ":result of set_convers_from_array"
      # log :debug, get_only_key(:result, @convers)

    end

    def get_convers_array(speaker_type)
      @convers.map.with_index do |cv,idx|
        str_out = "<#{idx}>"

        if not cv[:result]
          cv[:result] = cv["result"]
        end
        
        if cv[:speaker_type] == speaker_type

          @convers_mapping[idx] = speaker_type

          str_out = "<#{idx}>" + " " + cv[:result] + " "
        end

        str_out
        
      end
    end

    def do_mask2_for_field_org_result
      convers_results = @convers.map do |cv|
        if not cv[:org_result]
          cv[:org_result] = cv["org_result"]
        end
        
        " " + cv[:org_result] + " "
      end

      convers_results_new = do_mask2_for_obj(convers_results)

      @convers.each_index do |idx|
        @convers[idx][:org_result]= convers_results_new[idx]
      end

      # log :debug, ":org_result of domask2", 1
      # log :debug, get_only_key(:org_result, @convers), 1

    end

    
    def do_mask2_for_obj(convers_results)

      convers_results_join = convers_results.join(SEPARATOR)

      convers_results_join = normalized_text(convers_results_join, true)

      last_mask_pos = 0
      
      convers_results_join.gsub!($MASK_RULES[:number_cloud_regexp]) do |m|
        
        match = Regexp.last_match.clone

        str_replace_by = match[0]
        
        to_change = false
        
        number_of_digit = match[0].scan(/\d/).length

        if number_of_digit > 6 

          to_change = true

          idx_temp = match.pre_match.rindex($MASK_RULES[:nomask_leading_pattern])

          # log :debug, ":nomask_leading_pattern\n"+Regexp.last_match.to_s, 2

          if idx_temp
            if match.pre_match[idx_temp..-1] =~ $MASK_RULES[:nomask_leading_pattern_exclude]
              to_change = true
            else
              to_change = false
            end
          else
            to_change = true
          end

        end
        
        if (not to_change) and (3..5) === number_of_digit
          idx_temp = prepost_index(match,/(ทวน|อีกรอบ|อีกครั้ง)/)
          if idx_temp
            if idx_temp < 10
              to_change = true
            end
          end
        end
        
        if (not to_change) and number_of_digit > 3
          idx_temp = match.post_match.index(/หมด *อายุ/)
          if idx_temp

            if idx_temp < 30
              to_change = true
            end
          end
        end
        
        if to_change
          if match.post_match =~ $MASK_RULES[:nomask_tailing_pattern]

            to_change = false
          end
        end
        
        if to_change and match[0].match $MASK_RULES[:english_regexp]
          to_change = false
        end
        
        if to_change
          str_replace_by.gsub!(/\d/,"X") 
        end

        str_replace_by
      end

      convers_results_new = convers_results_join.split(SEPARATOR)

      convers_results_new
            
    end

    def do_mask3_for_obj(convers_results, convers_by_channel_idx)

      convers_results_join = convers_results.join(SEPARATOR)

      convers_results_join = normalized_text(convers_results_join, true)

      last_mask_pos = 0
      
      convers_results_join.gsub!($MASK_RULES[:number_cloud_regexp]) do |m|
        
        match = Regexp.last_match.clone

        str_replace_by = match[0]
        
        scores = [0]

        number_of_digit = match[0].gsub(/<.*>/,'').scan(/\d/).length

        # log :debug, "group of number", 1
        # log :debug, match[0], 1
        # log :debug, number_of_digit, 1
        
        if number_of_digit == 13
          scores.push 100
        elsif number_of_digit > 11 and number_of_digit < 15 
          scores.push 90
        elsif number_of_digit >= 13 
          scores.push 80
        elsif number_of_digit < 2
          scores.push -1000
        end

        scores = set_scores_by_context(scores, match.pre_match, match.post_match, convers_by_channel_idx)

        to_change = scores2bool(scores)
        
        if to_change
          str_replace_by.gsub!(/\d/,"X") 
        end

        # log :debug, "masked group of number", 1
        # log :debug, str_replace_by, 1

        str_replace_by
      end

      # log :debug, "convers_results_new", 1
      # log :debug, convers_results_join, 1

      convers_results_new = convers_results_join.split(SEPARATOR)

      convers_results_new
            
    end

    def set_scores_by_context(scores, pre_match, post_match, convers_by_channel_idx)
      new_scores = scores.clone

      current_idx = pre_match.scan(/<(\d*)>/).last[0].to_i

      unless current_idx == 0
        @convers_by_channel.each_index do |idx|
          
          if idx == convers_by_channel_idx
            str2test = get_previous_talk_from_string(pre_match, 500)
          else
            str2test = get_previous_talk(@convers_by_channel[idx], current_idx, 10, 500)
          end

          idx_temp = str2test.rindex($MASK_RULES[:nomask_leading_pattern])

          if idx_temp
            if str2test[idx_temp..-1] =~ $MASK_RULES[:nomask_leading_pattern_exclude]
              # new_scores.push(200)
            else
              new_scores.push(-200)
            end
          end

          idx_temp2 = str2test.rindex($MASK_RULES[:topics_all])

          if idx_temp2
            lastmatch2 = Regexp.last_match[0]

            if lastmatch2 =~ $MASK_RULES[:topics]
              unless lastmatch2 =~ $MASK_RULES[:topics_not]
                new_scores.push(201)
              end
            end
          end
        end
      end
      
      new_scores

    end

    def get_previous_talk_from_string(str_in, limit_str_length)

        last = limit_str_length > str_in.length ? -str_in.length : -limit_str_length

        str_in[last..-1]
        
    end

    def get_previous_talk(arr_in, current_idx, oldest, limit_str_length)
      old = oldest
      str_out = ""

      while str_out.length == 0 or str_out.length > limit_str_length
        min = current_idx-old
        max = current_idx-1

        min = min < 0 ? 0:min
        max = max < 0 ? 0:max

        str_out = arr_in[min..max].join

        if min == max 
          break
        end

        old = old - 1
      end


      str_out
    end

    def scores2bool(scores)

      # log :debug, "scores input to scores2bool", 1
      # log :debug, scores, 1

      scores_max = scores.max 
      scores_min = scores.min

      bool_out = false

      if scores_max + scores_min > 0
        bool_out = true
      end

      bool_out

    end
    
    def do_mask_for_field_result
      
      @convers.map! do |cv|
        
        last_topic_old = @last_topic

        if not cv[:result]
          cv[:result] = cv["result"]
        end
        get_topic cv[:result]
        
        cv_new = cv.clone
        
        str_to_test = cv[:result]

        if $MASK_RULES[:topics_all] =~ str_to_test
          str_new = cv[:result]


          str_to_append = ""
          
          subtopic = [last_topic_old]
          topics_change_pos = []
          
          idx_last = 0
          idx_match = ($MASK_RULES[:topics_all] =~ str_new)
          
          while idx_match

            topics_change_pos.push idx_match
            
            str_temp = str_new[idx_match..-1]
            
            str_topic_new = get_topic_from_str(str_temp, subtopic.last)
            if idx_match == 0
              subtopic = [str_topic_new]
            end
            subtopic.push str_topic_new
            
            idx_last = idx_match + subtopic.last.length
            idx_match = ($MASK_RULES[:topics_all] =~ str_new[(idx_last)..-1])
            
            if idx_match
              idx_match = idx_match + idx_last -1
            end
            
          end

          # if topics_change_pos != [0]
          if topics_change_pos[0] != 0
            pos_now = 0
            str_to_append = ""
            topics_change_pos.each_with_index do |item,idx|
              str_temp = str_new[pos_now..(item-1)]
              
              if $MASK_RULES[:topics] =~ subtopic[idx]
                str_temp = mask_text str_temp
              else
                str_temp = str_temp
              end
              
              str_to_append = str_to_append + str_temp
              
              pos_now = item
            end
          else
            pos_now = 0
          end

          str_temp = str_new[pos_now..-1]
          
          if $MASK_RULES[:topics] =~ subtopic.last and not $MASK_RULES[:topics_not] =~ subtopic.last

            str_temp = mask_text str_temp
          else

            str_temp = normalized_text_inverse str_temp
          end
          
          str_to_append = str_to_append + str_temp
          
          cv_new[:result] = normalized_text_inverse str_to_append
          
          @last_topic = subtopic.last

          
        elsif ($MASK_RULES[:topics]=~ @last_topic) or ($MASK_RULES[:topics]=~ last_topic_old)
          
          str_new = cv[:result]
          
          unless include_not? str_new
            str_new = normalized_text str_new
            str_new = mask_text str_new
            
            cv_new[:result] = str_new
          end
          
        else
          cv_new[:result] = normalized_text_inverse cv_new[:result]
        end
        
        cv_new
        
      end

      # log :debug, ":result of domask", 1
      # log :debug, get_only_key(:result, @convers), 1
      
    end

    
    def include_not?(str)
      
      $MASK_RULES[:topics_not]=~ str
      
    end

    
    def get_topic(str)
      
      $MASK_RULES[:topics_all].match str do |m|
        
        if $MASK_RULES[:topics].match str
          if not $MASK_RULES[:topics_must_not].match str
            @last_topic = m[0]
          end
        else
          @last_topic = m[0]
        end
        
        @no_num_count = 0
        
      end
      
    end

    
    def get_topic_from_str(str, str_init)
      str_out = str_init
      
      $MASK_RULES[:topics_all].match str do |m|

        if /หมดอายุ/ =~ str_init and (/ถัด/ =~ m[0] or /อีก.{,4}(ใบ|บัตร)/ =~ m[0]  or /(ใบ|บัตร)ที่/ =~ m[0])
          str_out = "เพื่อ ความ ปลอดภัย"
        else
          str_out = m[0]
        end
        
      end
      
      str_out
      
    end
    
    def mask_text(str_text)
      
      str_new = str_text

      if str_text =~ /\d/
        pat = Regexp.new "(\\d(?:\\d| |$)*)"
        
        str_new = str_new.gsub(pat) do |m|
          
          match = Regexp.last_match
          
          str_replace_by = match[0]
          str_number_matched = match[2]
          
          do_replace = true
          
          number_of_digit = match[0].scan(/\d/).length

          if number_of_digit < 3
            
            idx_temp2 = match.post_match.gsub(' ', '').index($MASK_RULES[:units])
            idx_temp1 = match.pre_match.gsub(' ', '').rindex($MASK_RULES[:units])
            last_matchPre = Regexp.last_match
            
            if idx_temp1 or idx_temp2

              if idx_temp2

                if idx_temp2 == 0
                  do_replace = false
                end
              end
              
              if do_replace and idx_temp1

                if match.pre_match.gsub(' ', '').length - idx_temp1 - last_matchPre[0].length < 3
                  do_replace = false
                end
              end
            end
          end
          
          if do_replace
            str_replace_by = str_replace_by.gsub(/\d/,REPLACEMENT_CHAR)
          else
            str_replace_by = normalized_text_inverse str_replace_by
          end
          
          str_replace_by
          
        end
        
        @no_num_count = 0
        
      else
        unless str_text.include? "X"
          if str_text.length > 200
            @last_topic = ""
          elsif str_text.length > 10
            @no_num_count = @no_num_count + 1
            
            if @no_num_count > $MASK_RULES[:no_num_count_max]
              @last_topic = ""
              
            end
          end
        end
        
      end
      
      str_new
      
    end
    
    def normalized_text(str_text, unconditionally = false)
      
      str_out = str_text
      
      str_out = " #{str_out} "
      str_out.gsub!(" ", "  ")
      
      $MASK_RULES[:normalizing_regexp] = $MASK_RULES[:hash_from_normalized_table].each_key.map do |k|
        Regexp.new " (" + k + ") "
      end
      $MASK_RULES[:normalizing_regexp] = Regexp.union $MASK_RULES[:normalizing_regexp]
      
      has_ever_match = false
      before_offset = -1
      str_out.gsub!($MASK_RULES[:normalizing_regexp]) do |m|
        match = Regexp.last_match
        
        str_replace_text = match[0]
        str_origin = match[0]
        
        if unconditionally
          str_replace_text = " " + $MASK_RULES[:hash_from_normalized_table][str_replace_text.strip] + " "
        else
          
          current_offset = match.offset(0)[0]

          after_offset = match.post_match.index($MASK_RULES[:normalizing_regexp])

          if not has_ever_match
            has_ever_match = true
            if after_offset
              if after_offset < 20
                str_replace_text = $MASK_RULES[:hash_from_normalized_table][str_replace_text.strip]
              end
            elsif match.post_match.length + match.pre_match.length < 20
              str_replace_text = $MASK_RULES[:hash_from_normalized_table][str_replace_text.strip]
            end
            
          else
            if current_offset - before_offset < 20
              str_replace_text = $MASK_RULES[:hash_from_normalized_table][str_replace_text.strip]
            elsif after_offset
              if after_offset < 20
                str_replace_text = $MASK_RULES[:hash_from_normalized_table][str_replace_text.strip]
              end
              
            end
            
          end

          before_offset = current_offset
        end
        
        str_replace_text
        
      end
      
      str_out.gsub!("  ", " ")
      
      str_out.strip!

      str_out = post_normalized_text(str_out)
      
      str_out
      
    end

    

    def post_normalized_text(strIn)
      strOut = strIn

      $MASK_RULES[:normalized_number_post_replace].each do |pair|
        strOut.gsub!(pair[0],pair[1])
      end

      strOut
    end
    
    def prepost_index(match, reg)
      idx = nil
      
      idx1 = match.post_match.index(reg)
      idx2 = match.pre_match.rindex(reg)
      
      if not idx1.nil? and not idx2.nil?
        idx = [match.begin(0) - idx2,idx1 ].min
      elsif idx1.nil? and not idx2.nil?
        idx = match.begin(0) - idx2
        
      elsif not idx1.nil? and idx2.nil?
        idx = idx1
      end
      
      idx
      
    end
    
    def normalized_text_inverse(str_text)
      
      str_out = str_text
      $MASK_RULES[:hash_from_normalized_table].each_pair do |k,v|
        str_out = str_out.gsub(v,k)
      end
      
      str_out
      
    end
    
    def lead_with_unit?(str_in)
      str_test = str_in.strip
      bln_out = ($MASK_RULES[:units] =~ str_test.gsub(/\s+/,''))
      
      exit_early = false
      while bln_out
        
        if Regexp.last_match[0].length+bln_out = str_test.length
          exit_early = true
          break
        end
        
        str_test = str_test[bln_out..-1]
        bln_out = ($MASK_RULES[:units] =~ str_test.gsub(/\s+/,''))
        
      end
      
      if not exit_early
        bln_out = false
      end
      
      bln_out
      
    end
    
    def follow_with_unit?(str_in)
      str_test = str_in.strip
      bln_out = ($MASK_RULES[:units] =~ str_test.gsub(/\s+/,''))
      if bln_out
        if bln_out != 0
          bln_out = false
        end
      end
      
      bln_out
      
    end

  end
end

