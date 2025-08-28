# frozen_string_literal: true

class AffiliateInvitation < ApplicationRecord
  belongs_to :seller, class_name: "User"
  belongs_to :invited_by, class_name: "User", optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :state, presence: true, inclusion: { in: %w[pending accepted rejected] }
  validates :fee_percent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :apply_to_all_products, inclusion: { in: [true, false] }

  scope :pending, -> { where(state: "pending") }
  scope :accepted, -> { where(state: "accepted") }
  scope :rejected, -> { where(state: "rejected") }

  def pending?
    state == "pending"
  end

  def accepted?
    state == "accepted"
  end

  def rejected?
    state == "rejected"
  end

  def can_be_accepted_by?(user)
    pending? && email == user.email
  end

  def can_be_rejected_by?(user)
    pending? && email == user.email
  end
end
