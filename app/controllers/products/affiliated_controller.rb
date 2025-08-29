# frozen_string_literal: true

class Products::AffiliatedController < Sellers::BaseController
  before_action :authorize

  def index
    @title = "Products"
    @props = AffiliatedProductsPresenter.new(current_seller,
                                             query: affiliated_products_params[:query],
                                             page: affiliated_products_params[:page],
                                             sort: affiliated_products_params[:sort])
                                        .affiliated_products_page_props
    respond_to do |format|
      format.html
      format.json { render json: @props }
    end
  end

  def destroy
    affiliate = DirectAffiliate.alive.find_by_external_id!(params[:id])

    if affiliate.affiliate_user != current_user
      return render json: { success: false, message: "Forbidden", id: affiliate.external_id }, status: :forbidden
    end

    affiliate.mark_deleted!

    AffiliateMailer.affiliate_self_removal(affiliate.id).deliver_later

    render json: { success: true, id: affiliate.external_id }
  end

  private
    def authorize
      super([:products, :affiliated])
    end

    def affiliated_products_params
      params.permit(:query, :page, sort: [:key, :direction])
    end
end
