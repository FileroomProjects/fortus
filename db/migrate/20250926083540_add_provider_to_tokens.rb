class AddProviderToTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :tokens, :provider, :string
  end
end
