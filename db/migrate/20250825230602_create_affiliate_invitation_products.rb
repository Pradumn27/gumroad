class CreateAffiliateInvitationProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :affiliate_invitation_products do |t|
      t.references :affiliate_invitation, null: false, foreign_key: true
      t.bigint "product_id", null: false
      t.decimal :fee_percent, precision: 5, scale: 2
      t.string :destination_url

      t.timestamps
    end
  end
end
