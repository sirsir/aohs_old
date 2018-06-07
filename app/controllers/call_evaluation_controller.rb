class CallEvaluationController < CallHistoriesController

  def check_agent_info
    ret = {}
    
    chkgroup = params[:target].include?("group") rescue false
    chkleader = params[:target].include?("leader") rescue false
    
    if params.has_key?(:agent_id) and params[:agent_id].to_i > 0
      user = User.where(id: params[:agent_id]).first
      unless user.nil?
        group = nil
        
        if chkgroup
          group = user.group_info({ evaluation_log: true })
          ret[:group] = { 
            id: group.id, name: group.short_name
          }
        else
          if params.has_key?(:group_id) and params[:group_id].to_i > 0
            group = Group.where(id: params[:group_id]).first
          end
        end
        
        if chkleader
          log = user.get_last_evaluation_log
          ret[:leaders] = []
          group.leader_info(nil, { evaluation_log: log }).each do |l|
            ret[:leaders] << {
              type: l.group_member_type.field_name,
              id: l.user_id,
              name: l.leader_info.display_name
            }
          end
        end
        
      end
    end
    
    render json: ret  
  end
  
end
