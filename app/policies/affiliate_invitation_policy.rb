# frozen_string_literal: true

class AffiliateInvitationPolicy < ApplicationPolicy
  def accept?
    record.can_be_accepted_by?(user)
  end

  def reject?
    record.can_be_rejected_by?(user)
  end

  def show?
    record.email == user.email || record.seller == user
  end

  def create?
    user.present?
  end

  def update?
    record.seller == user
  end

  def destroy?
    record.seller == user
  end
end
