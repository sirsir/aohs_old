class AddFieldShowscrNoty < ActiveRecord::Migration
  def change
    add_column  :message_logs, :display_cli_at, :datetime
    add_column  :message_logs, :display_at, :datetime
  end
end
