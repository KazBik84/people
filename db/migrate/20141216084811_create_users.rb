class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :encrypted_password
      t.integer :sign_in_count, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.datetime :team_join_time
      t.string :refresh_token
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :gh_nick
      t.string :skype
      t.integer :employment, default: 0
      t.string :phone
      t.boolean :archived, default: false
      t.boolean :available, default: true
      t.datetime :available_since
      t.boolean :without_gh, default: false
      t.string :uid
      t.text :user_notes
      t.integer :admin_role_id
      t.integer :primary_role_id
      t.integer :contract_type_id
      t.integer :location_id
      t.integer :team_id
      t.integer :leader_team_id
      t.timestamps
    end
    add_index :users, :admin_role_id
    add_index :users, :primary_role_id
    add_index :users, :contract_type_id
    add_index :users, :location_id
    add_index :users, :team_id
    add_index :users, :leader_team_id
  end
end
