# frozen_string_literal: true

class Api::Internal::AffiliateInvitationsController < Api::Internal::BaseController
  before_action :authenticate_user!

  def index
    authorize AffiliateInvitation

    invitations = AffiliateInvitation.pending
                                   .where(email: current_user.email)
                                   .includes(:seller, :invited_by)
                                   .order(created_at: :desc)

    render json: {
      invitations: invitations.map do |invitation|
        {
          id: invitation.id,
          seller_name: invitation.seller.name_or_username,
          seller_id: invitation.seller.id,
          invited_by_name: invitation.invited_by&.name_or_username || invitation.seller.name_or_username,
          fee_percent: invitation.fee_percent,
          apply_to_all_products: invitation.apply_to_all_products,
          destination_url: invitation.destination_url,
          products: invitation.apply_to_all_products ?
            invitation.seller.links.alive.map { |link|
              {
                id: link.external_id,
                name: link.name,
                fee_percent: invitation.fee_percent,
                destination_url: invitation.destination_url
              }
            } :
            (invitation.products || []).map do |inv_prod|
              link = invitation.seller.links.find_by_external_id_numeric(inv_prod["id"].to_i)
              next unless link
              {
                id: link.external_id,
                name: link.name,
                fee_percent: inv_prod["fee_percent"],
                destination_url: inv_prod["destination_url"]
              }
            end.compact,
          created_at: invitation.created_at
        }
      end
    }
  end

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
