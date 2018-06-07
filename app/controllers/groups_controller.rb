class GroupsController < ApplicationController
  
  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    @groups = Group.not_deleted.order(:seq_no)
  end
  
  def new
    @group = Group.new
    @leaders = @group.init_leaders
    @members = []
  end
  
  def create  
    @group = Group.new(group_params)
    @leaders = @group.init_leaders(leader_params)
    @group.do_init
    if @group.save
      @group.update_leader(leader_params)
      Group.repair_and_update_sequence_no
      db_log(@group, :new)
      flash_notice(@group, :new)
      redirect_to action: "edit", id: @group.id
    else
      render action: "new"
    end
  end
  
  def edit
    get_group
  end
  
  def update
    get_group
    if @group.update_attributes(group_params)
      @group.update_leader(leader_params)      
      Group.repair_and_update_sequence_no  
      db_log(@group, :update)
      flash_notice(@group, :update)
      redirect_to action: "edit", id: @group.id
    else
      render action: "edit"  
    end
  end
  
  def delete
    get_group
    if @group.can_delete?
      @group.do_delete
      @group.save
      Group.repair_and_update_sequence_no
      db_log(@group, :delete)
      flash_notice(@group, :delete)
    else
      flash_notice(@group, :cancel_delete)
    end
    render text: "deleted"
  end
  
  def destroy
    delete
  end
  
  def list
    case params[:t]
    when "atl-section"
      data = get_list_atl_section
    else
      data = get_list_from_group
    end
    render json: data
  end
  
  def info
    group = Group.where(id: group_id).first
    leads = group.leader_info
    leads = leads.map { |l|
      begin
        { member_type: l.member_type, user_id: l.user_id, display_name: User.where(id: l.user_id).first.display_name }
      rescue => e
        { member_type: l.member_type, user_id: l.user_id, display_name: nil }
      end
    }
    data = {
      id: group.id,
      title: group.display_name,
      leads: leads
    }
    render json: data
  end
  
  private
  
  def get_list_from_group
    # default group list
    is_long_name = (params[:fullname] == "true")
    groups = Group.select([:id, :name, :short_name, :pathname]).not_deleted
    if is_long_name
      groups = groups.order(pathname: :asc)
    else
      groups = groups.order(short_name: :asc)
    end
    if params.has_key?(:q)
      q = params[:q]
      groups = groups.where("short_name LIKE ?","#{q}%")
    end
    if is_long_name
      data = groups.all.map { |g| { id: g.id, name: g.display_name, text: g.display_name } }
    else
      data = groups.all.map { |g| { id: g.id, name: g.short_name, text: g.short_name } }
    end
    return data
  end
  
  def get_list_atl_section
    sects = SystemConst.find_const("atl-sections")
    if params.has_key?(:q)
      q = params[:q]
      sects = sects.where("code LIKE '#{q}%' OR name LIKE '#{q}%'")
    end
    data  = sects.all.map { |g| { id: g.code, name: "#{g.code}: #{g.name}", text: "#{g.code}: #{g.name}" } }
    return data
  end
  
  def get_group
    @group = Group.where(id: group_id).first
    @leaders = @group.init_leaders(leader_params)
    @lead_hists = @group.group_member_histories.only_leader.all
    @members = @group.group_members.only_member.all
  end
  
  def group_id
    return params[:id].to_i
  end
  
  def group_params
    params.require(:group).permit(
            :description,
            :short_name,
            :group_type,
            :ldap_dn,
            :parent_id) rescue {}
  end
  
  def leader_params
    list = []
    if params[:group_leaders].present?
      params[:group_leaders].each { |mem_type, user_id|
        list << {
          user_id: user_id,
          member_type: mem_type
        }
      }
    end
    return list
  end
  
end
