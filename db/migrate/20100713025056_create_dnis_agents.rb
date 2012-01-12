class CreateDnisAgents < ActiveRecord::Migration
  def self.up
    create_table :dnis_agents do |t|
      t.column  :dnis,    :string, :limit => 10
      t.column  :ctilogin, :string, :limit => 50
      t.column  :team, :string, :limit => 50
      t.timestamps
    end
  end

  def self.down
    drop_table :dnis_agents
  end
end
