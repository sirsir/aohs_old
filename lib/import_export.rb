require 'extends/import_base'
require 'extends/export_base'

module ImportExport
  
  class ImportExtension < ImportBase
    
    def correct_headers_info?
      return @cols.include?(:number)
    end
    
    def map_colname(col_name)
      case col_name.to_s.downcase.gsub(" ","_")
      when /(ext)/, /(extension)/
        return :number
      when /(ip)/, /(ip_adr)/, /(ip_address)/, /(ipv4)/
        @defined_ip = true
        return :ip_address
      when /(name)/, /(computer_name)/, /(computer)/
        return :computer_name
      when /(did)/
        @defined_did = true
        return :did
      else
        return false
      end
    end
 
    def insert_or_update(rec)
      is_changed = false
      rec[:new_record] = false
      ext = Extension.where(number: rec[:number]).first
      if ext.nil?
        ext = Extension.new(new_attr(rec))
        is_changed = true
        rec[:new_record] = true
      else
        if require_update?
          ext.attributes = new_attr(rec)
          is_changed = true
        end
      end
      
      if is_changed
        if ext.save
          if @defined_ip
            comp = ext.update_computer_info(rec)
            unless comp.errors.empty?
              rec[:errors].concat(comp.errors.full_messages)
            end
          end
          if @defined_did
            did = ext.update_dids_info(rec)
            unless did.errors.empty?
              rec[:errors].concat(did.errors.full_messages)
            end
          end
        else
          rec[:errors].concat(ext.errors.full_messages)
          rec[:errors] = rec[:errors].uniq.sort
        end
      end
      return rec
    end
    
    def new_attr(rec)
      return ({
        number: rec[:number]
      }).remove_blank!
    end
    
  end
  
  class ImportUser < ImportBase
    
    def correct_headers_info?
      
      return (@cols.include?(:login_name)and @cols.include?(:employee_id))
      
    end
    
    def map_colname(col_name)

      case col_name.to_s.downcase.gsub(" ","_")
      when /(login)/, /(username)/
        return :login_name
      when /(full_name)/, /(full_name_en)/, /(name_en)/, /(name)/
        return :full_name_en
      when /(full_name_th)/, /(name_th)/
        return :full_name_th
      when /(email)/, /(e-mail)/, /(mail)/
        return :email
      when /(citizen)/
        return :citizen_id
      when /(employee)/
        return :employee_id
      when /(sex)/
        return :sex_name
      when /(role)/
        return :role_name
      when /(group)/, /(team)/
        return :group_name
      else
        return false
      end

    end
 
    def insert_or_update(rec)
      
      user = User.where(login: rec[:login_name], employee_id: rec[:employee_id]).first
      is_changed = false
      rec[:new_record] = false
      
      if user.nil?
        user = User.new(new_attr(rec))
        user.do_active(true)
        group_member = GroupMember.new({ group_id: rec[:group_id] })
        is_changed = true
        rec[:new_record] = true
      else
        if require_update?
          user.attributes = new_attr(rec)
          group_member = GroupMember.only_member.where(user_id: user.id).first
          unless rec[:group_id].nil?
            group_member.group_id = rec[:group_id]
          end
          is_changed = true
        end
      end
      
      if is_changed
        if user.save
          group_member.set_as_member
          group_member.user_id = user.id
          group_member.save  
        else
          rec[:errors].concat(user.errors.full_messages)
          rec[:errors] = rec[:errors].uniq.sort
        end
      end
      
      return rec
    
    end
    
    def new_attr(rec)
    
      return ({
        login:        rec[:login_name],
        employee_id:  rec[:employee_id],
        citizen_id:   rec[:citizen_id],
        full_name_en: rec[:full_name_en],
        full_name_th: rec[:full_name_th],
        sex:          rec[:sex_code],
        email:        rec[:email],
        role_id:      rec[:role_id]
      }).remove_blank!
    
    end
    
  end

  class ExportUser < ExportBase

    def get_data(conditions=[])
      
      # @conds = conditions
      return User.ransack(@conds).result.only_active.not_locked.order("login").all
    
    end
    
    def fields(r)
      
      return [
        r.login,
        r.employee_id,
        r.citizen_id,
        r.full_name,
        r.group_name,
        r.role_name,
        r.email,
        r.sex_name,
        r.state_name
      ]
    
    end
    
    def headers
      
      return [
        'username',
        'employee_id',
        'citizen_id',
        'full_name',
        'group',
        'role',
        'email',
        'sex',
        'status'
      ]
    
    end
    
    def file_name
      
      return ["users",FileName.current_dt].join
    
    end
    
  end
  
  def self.import_from_file(target_import,input_file, opts={})
    
    case target_import
    when :user
      im = ImportUser.new(input_file, opts)
      im.update
      import_result = im.results
    when :extension
      im = ImportExtension.new(input_file, opts)
      im.update
      import_result = im.results
    else
      return nil
    end
    
    return import_result
  
  end
  
  def self.export_to_file(target_export, opts={})
    
    case target_export
    when :user
      ep = ExportUser.new(opts)
      exported_file = ep.export_to_csv
    when :extension
    else
      return nil
    end

    return exported_file
  
  end
  
end