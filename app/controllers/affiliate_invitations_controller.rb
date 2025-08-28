# frozen_string_literal: true

class AffiliateInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitation

  def accept
    authorize @invitation

    return redirect_to root_path, alert: "Invitation is not pending." unless @invitation.pending?
    return redirect_to root_path, alert: "This invitation was not sent to your email." if @invitation.email != current_user.email

    # Check if user already has an affiliate relationship with this seller
    existing_affiliate = @invitation.seller.direct_affiliates.alive.find_by(affiliate_user_id: current_user.id)
    if existing_affiliate
      return redirect_to root_path, alert: "You are already an affiliate for this seller."
    end

    DirectAffiliate.transaction do
      affiliate = DirectAffiliate.create!(
        seller_id: @invitation.seller_id,
        affiliate_user_id: current_user.id,
        affiliate_basis_points: (@invitation.fee_percent * 100).to_i,
        destination_url: @invitation.destination_url,
        apply_to_all_products: @invitation.apply_to_all_products,
        send_posts: true
      )

      if @invitation.apply_to_all_products
        # Create product affiliates for all seller's products
        @invitation.seller.links.alive.each do |link|
          affiliate.product_affiliates.create!(
            link_id: link.id,
            affiliate_basis_points: (@invitation.fee_percent * 100).to_i,
            destination_url: @invitation.destination_url
          )
        end
      else
        # Create product affiliates for specific products from invitation
        (@invitation.products || []).each do |inv_prod|
          link = @invitation.seller.links.find_by_external_id_numeric(inv_prod["id"].to_i)
          next unless link

          affiliate.product_affiliates.create!(
            link_id: link.id,
            affiliate_basis_points: (inv_prod["fee_percent"].to_f * 100).to_i,
            destination_url: inv_prod["destination_url"]
          )
        end
      end

      @invitation.update!(state: "accepted")

      # Schedule workflow jobs for the new affiliate
      affiliate.schedule_workflow_jobs

      # Send notification email to seller
      AffiliateMailer.affiliate_invitation_accepted(@invitation.id).deliver_later
    end

    redirect_to affiliates_path, notice: "Affiliate invitation accepted successfully! You are now an affiliate for #{@invitation.seller.name_or_username}."
  end

  def reject
    authorize @invitation

    return redirect_to root_path, alert: "Invitation is not pending." unless @invitation.pending?
    return redirect_to root_path, alert: "This invitation was not sent to your email." if @invitation.email != current_user.email

    @invitation.update!(state: "rejected")

    # Send notification email to seller
    AffiliateMailer.affiliate_invitation_rejected(@invitation.id).deliver_later

    redirect_to root_path, notice: "Affiliate invitation declined."
  end

  private

  def set_invitation
    @invitation = AffiliateInvitation.find(params[:id])
  end
end
