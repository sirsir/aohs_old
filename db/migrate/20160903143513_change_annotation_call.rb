class ChangeAnnotationCall < ActiveRecord::Migration
  def change
    add_column    :call_annotations, :start_time, :datetime
    add_column    :call_annotations, :end_time, :datetime
    change_column :call_annotations, :annot_type, :string, limit: 10, null: false, default: ""
  end
end
