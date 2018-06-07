class GroupMembersController < ApplicationController

  before_action :authenticate_user!

  def update_member
    
    group_id = params[:group_id].to_i
    user_id  = params[:user_id].to_i
    act      = params[:act]
    
    update_or_delete_member(group_id, user_id, act)
    data = get_list(user_id)

    render json: { result: "ok", members: data }
    
  end
  
  private
  
  def update_or_delete_member(group_id,user_id,act="add")
    
    if group_id > 0 and user_id > 0
      
      ds = { group_id: group_id, user_id: user_id }
      
      group_member = GroupMember.where(ds).first
      
      if group_member.nil?
        if act == "add"
          group_member = GroupMember.new(ds)
          group_member.set_as_follower
          group_member.save
        end
      elsif act == "delete"
        group_member.delete
      end
      
    end
    
  end
  
  def get_list(user_id)
    
    group_members = GroupMember.joins(:group).only_follower.where(user_id: user_id)
    group_members = group_members.order('groups.level_no').all
    
    data = []
    group_members.each do |gm|
      g = gm.group
      data << {
        group_id:   gm.group_id,
        item_no:    g.level_no,
        group_name: g.short_name,
        desc:       g.name
      }
    end
    
    return data
  
  end
  
end
