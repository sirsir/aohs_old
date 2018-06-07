module ApplicationHelper
  
  include SysPermission::ActionPermission
  
  # include javascript of controller
  
  def controller_javascript_tags
    
    lo_files = []
    
    required_cc_files.each do |f|
      fn = [f,"js"].join(".")
      unless Rails.application.assets.find_asset(fn).nil?
        lo_files << javascript_include_tag(fn)
      end
    end

    lo_files.join.html_safe

  end
  
  # include stylesheet of controller
  
  def controller_stylesheet_tags

    lo_files = []
    
    required_cc_files.each do |f|
      fn = [f,"css"].join(".")
      unless Rails.application.assets.find_asset(fn).nil?
        lo_files << stylesheet_link_tag(fn)
      end
    end

    lo_files.join.html_safe

  end

  def tag_stylesheets_link
    
    stylesheet_link_tag url_for(controller: 'tags', action: 'tag_style', format: :css)
    
  end
  
  def content_stylesheets_link(type=nil)
    
    stylesheet_link_tag url_for(controller: 'content_style', action: 'content_style', format: :css, type: type)
    
  end
  
  def other_site_locations
    locs = []
    begin
      Settings.other_sites.each do |lname, lval|
        locs << {
          code: lname.to_s,
          display_name: lval.display_name,
          url: lval.url
        }
      end
      locs = [] if locs.length <= 1
    rescue
    end
    return locs
  end
  
  def current_site_location(s_field=:url)
    begin
      cloc = (other_site_locations.select{ |x| x[:code] == Settings.site.location_code }).first
      return cloc[s_field]
    rescue
      return nil
    end
  end
  
  # nav and navbar
  
  def nav_link_to(link_name, opts={})
    result = {
      class: [],
      url_params: "#",
      name: nil,
      icon: nil
    }
    
    case link_name.to_sym
    when :view
      result[:name] = "View"
      result[:icon] = 'table'
      result[:url_params] = { action: "index" }
      unless controller.action_name == "index"
        result[:url_params] = result[:url_params].merge(index_with_filter_url)
      end
    when :new, :create
      result[:name] = "Add"
      result[:icon] = 'plus'
      result[:url_params] = { action: "new" }
    when :edit, :change
      result[:name] = "Edit"
      result[:icon] = 'pencil'
      result[:url_params] = { action: "edit" }
    when :filter, :search
      result[:name] = "Filter"
      result[:icon] = 'filter'
      result[:class] << "filter-button"
      result[:class] << "filter-active active" if is_filter_on?
    when :export_dialog
      result[:name] = "Export"
      result[:icon] = 'download'
      result[:class] << "btn-export-dialog"
      if defined? @parm_filters
        result[:url_params] = ({ action: "export", dlby: current_user.id }).merge(@parm_filters)
      else
        result[:url_params] = { action: "export", dlby: current_user.id }
      end
    when :import
      result[:name] = "Import"
      result[:icon] = 'upload'
      result[:url_params] = { action: "import" }
    when :show, :detail
      result[:name] = "Detail"
      result[:icon] = 'info'
      result[:url_params] = { action: "show" }
    else
      result[:name] = link_name.to_s.capitalize
      result[:url_params] = { action: link_name.to_s }
    end
    
    if opts.has_key?(:label)
      result[:name] = opts[:label]
    end
    
    if opts.has_key?(:params)
      result[:url_params] = result[:url_params].merge(opts[:params])
    end
    
    if result[:url_params].is_a?(Hash)
      selected = false
      result[:url_params].each_pair do |k,v|
        selected = (params.include?(k) and params[k] == v)
        break unless selected
      end
      result[:class] << "active" if selected
    end
    
    content_tag :li, class: result[:class].join(" ") do
      content_tag :a, "data-action-name": result[:name], href: url_for(result[:url_params]) do
        unless result[:icon].nil?
          concat(icon result[:icon])
        end
        concat(result[:name])
      end
    end
  end
  
  def horizontal_bar
    content_tag :div,nil, class: "mnt-horizontal-bar"
  end
  
  def hbs_template(name,&block)
    content_tag :script, capture(&block), id: name, type: "text/x-handlebars"
  end
  
  # forms
  
  def panel_form(&block)
     
    content_tag :div, class: "panel panel-default panel-form" do
      concat(content_tag(:div, capture(&block), class: "panel-form-sb"))
    end
    
  end  
  
  def panel_filter(&block)
    
    content_tag(:div, capture(&block), class: "panel panel-default panel-filter")  
  
  end
  
  def panel_show(&block)
    
    content_tag(:div, capture(&block), class: "panel panel-default panel-show")
    
  end
  
  def form_filter_tag(name, url, opts={}, &block)

    elm_cls = ["form-horizontal"]
    if opts[:class].present?
      elm_cls.concat(opts[:class].split(" "))
    end

    form_tag url, { method: :get, role: "form", class: "container-fluid " + elm_cls.join(" ") } do
      concat(content_tag(:div, capture(&block), class: "col-sm-11", style: "padding: 0em"))
      btns = submit_tag("OK", class: "btn btn-primary btn-mntfilter form-control", style: "margin-bottom: 1em")
      btns.concat(content_tag(:button,"Clear", type: "button", value:"reset", class: "btn btn-default btn-reset-form form-control", style: "margin-bottom: 1em"))
      concat(content_tag(:div,btns, class: "col-sm-1", style: "padding: 0em"))
    end
  end
  
  def field_group_tag(name=nil, label=nil, opts={},  &block)
    
    elm_cls = ["form-group"]
    if opts[:class].present?
      elm_cls.concat(opts[:class].split(" "))
    end

    content_tag :div, class: elm_cls.join(" ") do
      concat(label_tag name, label, class: "col-sm-2 control-label")
      concat(content_tag :div, capture(&block), class: "col-sm-6")
    end
    
  end

  def field_group_inline_tag(name=nil, label=nil, opts={},  &block)
    
    elm_cls = [""]
    if opts[:class].present?
      elm_cls.concat(opts[:class].split(" "))
    end

    content_tag :div, class: "col-md-4 col-sm-6 " + elm_cls.join(" "), style: "margin-bottom:1em" do
      concat(label_tag name, label, class: "col-sm-4 control-label")
      concat(content_tag :div, capture(&block), class: "col-sm-8")
    end
    
  end

  def html_template(id, opts={}, &block)
    
    tag_id = "#{id}"
    
    content_tag :script, capture(&block) , id: tag_id, type: "text/x-handlebars"
    
  end
  
  def info_group_tag(label_name)
    
    content_tag(:div, label_name, class: "info-group")
    
  end
  
  def select_file_type(fext=[])
    
    select_tag :file_type, options_for_select(SystemConst.filetype_options(fext)), { class: "form-control" }

  end
  
  def field_tag(label_name,value)
    
    content_tag :div, class: "col-md-6 info-field-group" do
      concat(content_tag(:div, label_name, class: "col-md-3 info-label"))
      concat(content_tag(:div, value, class: "col-md-9 info-field"))
    end
    
  end
  
  def form_message_tag(model_obj)
    
    @errors = model_obj.errors
    render 'shares/form_messages'    
  
  end

  def help_box(txt,&block)
    
    content_tag :div do
      concat(content_tag(:div, nil, class: "col-sm-3"))
      concat(content_tag(:div, txt, class: "help-block-cs col-sm-9"))
    end
    
  end
  
  # pagination
  
  def paginate_panel_tag(res, opts={})
    
    render partial: "shares/mnt_paginate", locals: { res: res, opts: opts }
  
  end

  # table
  
  def rowmnt_button_tag(mo_obj,opt='sed')
    # opt meaning
    # s=show, e=edit, d=delete, u=undelete 
    render partial: 'shares/mnt_buttons', locals: { mo: mo_obj, opt: opt.to_s.split("") }
  end

  def panel_tableview(&block)
    
    content_tag(:div, capture(&block), class: "panel panel-default panel-tblview")  
  
  end

  def table_tag(name=:default, opts={}, &block)
    
    class_name = "table table-striped table-bordered table-hover table-#{name.to_s}"
    
    html_opts = {}
    html_opts[:class] = class_name
    html_opts[:id]    = opts[:id] if opts[:id].present?
    
    content_tag(:table, capture(&block), html_opts)
    
  end
  
  def th_tag(name, opts={}, &block)
  
    content_tag :th, class: th_order_class(name,opts) do
      col_name = opts[:label] || name.to_s.gsub("_"," ").titleize
      content_tag :span do
        if opts.has_key?(:order) and opts[:order] == true
          concat(content_tag :a, col_name, href: th_order_url(name))
        else
          concat(col_name)
        end
      end
    end
    
  end
  
  def help_dialog_button(id, type="link")
    content_tag :button, icon('question-circle'), type: "button", class: 'btn-link btn-help-dialog', "data-man-id": id
  end
  
  def td_tag
    
  end
  
  def more_options_tag
    
    render "kaminari/more_opts"  
  
  end
  
  def no_record_tag
    
    render 'shares/no_record_aa'
    
  end
  
  # current controller and action
  
  def on_page_portal?
    return (controller.controller_name == "home" and controller.action_name == "portal")  
  end
  
  def is_index_action?
    
    ["index","view"].include?(controller.action_name)
    
  end
  
  def is_create_action?
    
    ["new", "create"].include?(controller.action_name)
    
  end
  
  def is_edit_action?
    
    ["edit","update"].include?(controller.action_name)
  
  end

  def is_show_action?
    
    ["show","detail"].include?(controller.action_name)
    
  end
  
  def is_current_controller?(ctrln)
    
    (controller.controller_name.to_s == ctrln.to_s)
  
  end

  def curr_controller(ctrln)
    
    (is_current_controller?(ctrln) ? "cur-controller" : "")  
  
  end

  def logged_as_admin?
    
    if current_user and current_user.is_admin?
      true
    else
      false
    end
    
  end
  
  def company_logo_path
    # get image file from path
    logo_filepath = "#{Settings.site.codename}.png"
    if File.exists?(File.join(Rails.root, "app/assets/images/logo", logo_filepath))
      return logo_filepath
    end
    return "default.png"
  end
  
  def icon(name,opts={})  
    fa_icon name, opts  
  end
  
  def js_void
    return "javascript:void(0);".html_safe 
  end
  
  def last_12_months
    
    list = []
    smon = Date.today.beginning_of_month
    12.times do
      list << smon.strftime("%B %Y")
      smon = (smon - 1).beginning_of_month
    end
    
    return list
  
  end
  
  def include_token
    
    javascript_tag("window._frmTk = '#{form_authenticity_token}';")
  
  end
  
  def user_avatar_url(id)
    url_for(controller: 'users', action: 'avatar', id: id)
  end
  
  def loading_images
    
    imgs = []
    8.times do |i|
      imgs << "loading/ring-alt-#{i+1}.gif"
    end
    return imgs
  
  end
  
  def menu_selected_class(ctln)
    ctlns = ctln.split(/ +/)
    ctlns.each do |ctl|
      if is_current_controller?(ctl)
        return "mn-selected"
      end
    end
    return ""
  end
  
  def get_display_table
    case params[:controller]
    when "call_histories"
      :call_history
    when "call_evaluation"
      :call_evaluation
    when "search"
      :text_search
    else
      :error
    end
  end
  
  def layout_blank?
    params[:lyt] == 'blank'
  end
  
  def display_for?(codenames)
    #
    # to select view/page/function to display
    # for each customer/site
    #
    if codenames.is_a?(String) or codenames.is_a?(Symbol)
      codenames = [codenames]
    end
    codenames = codenames.map { |c| c.to_s }
    return codenames.include?(Settings.site.codename)
  end
  
  def enable_function_for?(codenames)
    return display_for?(codenames)
  end
  
  def disable_function_for?(codenames)
    return (not display_for?(codenames))
  end
  
  protected

  def action_active_class(lst=[])
    
    lst = lst.map { |l| l.to_s }
    if lst.include?(controller.action_name)
      "active"
    else
      nil
    end
    
  end

  def th_order_class(field_name,opts={})
  
    h = ""
    
    if opts.has_key?(:order) and opts[:order] == true
      h = "order "
      f = params[:order].to_s
      s = params[:sort].to_s 
      h << s if field_name.to_s == f
    end
    
    return h.strip
  
  end

  def th_order_url(field_name)
  
    p = params.clone
    
    if field_name.to_s == p[:order].to_s
      p[:sort] = ((p[:sort].to_s == "desc") ? "asc" : "desc")
    else
      p[:order] = field_name.to_s
    end
    
    return url_for(p)
  
  end

  def is_filter_on?
    return (@filter_on == true)
  end
  
  def required_cc_files
    
    possi_files = []
    
    possi_files << controller.controller_name.to_s
    possi_files << [
      controller.controller_name.to_s,
      controller.action_name.to_s
    ].join("_")
    
    # fixed for render action  
    case controller.action_name
    when "update"
      possi_files << [controller.controller_name.to_s, "edit"].join("_")
    when "create"
      possi_files << [controller.controller_name.to_s, "new"].join("_")
    end
    
    return possi_files
  
  end
  
  def default_input_date_range(d_opt=:today, remember=true)
    sdate = Date.today
    edate = Date.today
    
    case d_opt
    when :this_month
      sdate = sdate.beginning_of_month
    when :this_week
      sdate = sdate.beginning_of_week
    when :last_6_months
      sdate = sdate.beginning_of_month - 6.months
    end
    
    if remember
      tdate = get_session_report_param(:date_range)
      unless tdate.nil?
        return tdate
      end
    end
    return "#{sdate.to_formatted_s(:web)} - #{edate.to_formatted_s(:web)}"
  end
  
  private
  
  def get_session_report_param(name)
    keyname = "report_#{name}"
    if session[keyname].present? and not session[keyname].blank?
      return session[keyname]
    end
    return nil
  end
  
end
