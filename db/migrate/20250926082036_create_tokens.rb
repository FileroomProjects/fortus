class CreateTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :tokens do |t|
      t.text :access_token
      t.text :refresh_token
      t.string :expires_in
      t.datetime :expires_at

      t.timestamps
    end
  end
end
