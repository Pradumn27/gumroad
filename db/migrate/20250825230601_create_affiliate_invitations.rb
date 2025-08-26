class CreateAffiliateInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :affiliate_invitations do |t|
      t.references :seller, null: false, foreign_key: { to_table: :users, name: "fk_affiliate_invitations_seller" }
      t.references :invited_by, null: true, foreign_key: { to_table: :users, name: "fk_affiliate_invitations_invited_by" }
      t.string :email, null: false
      t.string :destination_url
      t.decimal :fee_percent, precision: 5, scale: 2
      t.boolean :apply_to_all_products, default: false
      t.string :state, null: false, default: "pending" # pending | accepted | rejected

      t.timestamps
    end
  end
end
