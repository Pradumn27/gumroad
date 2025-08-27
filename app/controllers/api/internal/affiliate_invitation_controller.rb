# frozen_string_literal: true

class Api::Internal::AffiliateInvitationsController < Api::Internal::BaseController
  before_action :authenticate_user!

  def accept
    invitation = AffiliateInvitation.find(params[:id])
    authorize invitation

    return render json: { success: false, message: "Invitation is not pending." } unless invitation.pending?
    return render json: { success: false, message: "This invitation was not sent to your email." } if invitation.email != current_user.email

    DirectAffiliate.transaction do
      affiliate = DirectAffiliate.create!(
        seller_id: invitation.seller_id,
        affiliate_user_id: current_user.id,
        affiliate_basis_points: (invitation.fee_percent * 100).to_i,
        destination_url: invitation.destination_url,
        apply_to_all_products: invitation.apply_to_all_products
      )

      (invitation.products || []).each do |inv_prod|
        affiliate.product_affiliates.create!(
          link_id: inv_prod["id"],
          affiliate_basis_points: (inv_prod["fee_percent"].to_f * 100).to_i,
          destination_url: inv_prod["destination_url"]
        )
      end

      invitation.update!(state: "accepted")
    end

    render json: { success: true }
  end

  def reject
    invitation = AffiliateInvitation.find(params[:id])
    authorize invitation

    return render json: { success: false, message: "Invitation is not pending." } unless invitation.pending?

    invitation.update!(state: "rejected")
    render json: { success: true }
  end

  private

  def invite_params
    params.require(:affiliate).permit(
      :email,
      :destination_url,
      :fee_percent,
      :apply_to_all_products,
      products: [:id, :fee_percent, :destination_url, :enabled]
    )
  end

  def filter_enabled_products(products)
    return [] if products.blank?
    products.select { |p| ActiveModel::Type::Boolean.new.cast(p["enabled"]) }
  end
end
