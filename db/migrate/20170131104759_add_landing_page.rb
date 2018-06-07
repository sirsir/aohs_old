class AddLandingPage < ActiveRecord::Migration
  def change
    add_column :roles, :landing_page, :string, limit: 100
  end
end
