# frozen_string_literal: true

class AffiliateInvitation < ApplicationRecord
  include ExternalId

  belongs_to :affiliate, foreign_key: :affiliate_id

  def pending?
    persisted? && affiliate&.alive?
  end

  def accept!
    destroy!
    AffiliateMailer.affiliate_invitation_accepted(affiliate_id).deliver_later
  end

  def decline!
    self.class.transaction do
+      affiliate.mark_deleted!
+      destroy!
+      AffiliateMailer.affiliate_invitation_declined(affiliate_id).deliver_later
+    end
  end
end
