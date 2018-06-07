module CustomQueryReport
  
  ############################################################################################
  # Aeon Query
  ############################################################################################
  
  module AeonQuery
    
    def get_list_groupinfo_from_atl(l_src=:voice_log)
      ret = {}
      
      sql = []
      if l_src == :voice_log
        sql << "SELECT v.agent_id, MAX(m.user_atl_id) AS user_atl_id"
        sql << "FROM voice_logs v JOIN voice_log_atlusr_maps m ON v.id = m.voice_log_id"
        sql << "WHERE v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
        sql << "GROUP BY v.agent_id"
      end
      if l_src == :atl_log
        sql << "SELECT a.user_id AS agent_id, MAX(a.id) AS user_atl_id"
        sql << "FROM user_atl_attrs a JOIN users u ON a.user_id = u.id"
        sql << "WHERE a.updated_at <= '#{@opts[:edatetime]}'"
        sql << "AND u.state <> 'D'"
        sql << "GROUP BY a.user_id"
      end
      sql_s = jn_sql(sql)
      
      sql = []
      sql << "SELECT s1.agent_id, s1.user_atl_id, a.* ,c1.name AS team_name, c2.name AS perf_group_name, c3.name AS section_name"
      sql << "FROM (#{sql_s}) s1"
      sql << "JOIN user_atl_attrs a ON s1.user_atl_id = a.id"
      sql << "LEFT JOIN system_consts c1 ON a.team_id = c1.code AND c1.cate = 'atl-teams'"
      sql << "LEFT JOIN system_consts c2 ON a.performance_group_id = c2.code AND c2.cate = 'atl-perfgroups'"
      sql << "LEFT JOIN system_consts c3 ON a.section_id = c3.code AND c3.cate = 'atl-sections'"
      sql << "WHERE a.user_id > 0"
      
      if @opts[:agent_name].present?
        sql << "AND " + sql_user_exist(@opts[:agent_name],"s1.agent_id")
      end
      
      if @opts[:group_name].present?
        sql << "AND c1.name LIKE '%#{@opts[:group_name]}%'"
      end
      
      if @opts[:section_name].present?
        sects = SystemConst.find_const("atl-sections").namecode_start_with(@opts[:section_name]).all
        unless sects.empty?
          sects = sects.map { |s| s.code }
          sql << "AND c3.code IN (#{sql_valmap(sects)})"
        else
          sql << "AND c3.code = 'N/A'"
        end
      end
      
      result = select_sql(jn_sql(sql))
      result.each do |r|
        uid = r["agent_id"].to_s
        ret[uid] = {
          agent_id: r["agent_id"],
          operator_id: r["operator_id"],
          team_id: r["team_id"],
          team_name: r["team_name"],
          performance_group_id: r["performance_group_id"],
          performance_group_name: r["perf_group_name"],
          section_id: r["section_id"],
          section_name: r["section_name"]
        }
      end
      return ret
    end

    def sql_join_find_by_atl
      sql = []
      sql << "SELECT v.agent_id, MAX(m.user_atl_id) AS user_atl_id"
      sql << "FROM voice_logs v JOIN voice_log_atlusr_maps m"
      sql << "ON v.id = m.voice_log_id"
      sql << "WHERE v.start_time BETWEEN '#{@opts[:sdatetime]}' AND '#{@opts[:edatetime]}'"
      sql << "GROUP BY v.agent_id, m.user_atl_id"
      sql_s = jn_sql(sql)
      
      sql = []
      sql << "SELECT s1.agent_id"
      sql << "FROM (#{sql_s}) s1"
      sql << "JOIN user_atl_attrs a ON s1.user_atl_id = a.id"
      if @opts[:group_name].present?
        sql << "LEFT JOIN system_consts c1 ON a.team_id = c1.code AND c1.cate = 'atl-teams'"
      end
      if @opts[:section_name].present?
        sql << "LEFT JOIN system_consts c3 ON a.section_id = c3.code AND c3.cate = 'atl-sections'"
      end
      sql << "WHERE a.user_id > 0"
      if @opts[:group_name].present?
        sql << "AND c1.name LIKE '%#{@opts[:group_name]}%'"
      end
      if @opts[:section_name].present?
        sects = SystemConst.find_const("atl-sections").namecode_start_with(@opts[:section_name]).all
        unless sects.empty?
          sects = sects.map { |s| s.code }
          sql << "AND c3.code IN (#{sql_valmap(sects)})"
        else
          sql << "AND c3.code = 'N-A'"
        end
      end
      sql = jn_sql(sql)
      return sql
    end
  
    # end AeonQuery #
  end
  
  # end module
end
