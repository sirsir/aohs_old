class AddProcNamePgInfo < ActiveRecord::Migration
  def change
    add_column  :program_infos, :proc_name, :string,  limit: 100
  end
end
