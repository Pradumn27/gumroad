class DropAffiliateInvitations < ActiveRecord::Migration[7.1]
  def change
    drop_table :affiliate_invitation_products, if_exists: true
    drop_table :affiliate_invitations, if_exists: true
  end
end
