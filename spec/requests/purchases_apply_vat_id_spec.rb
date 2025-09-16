# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Purchases Apply VAT ID to Subscription", type: :request do
  let(:seller) { create(:user) }
  let(:buyer) { create(:user) }
  let(:product) { create(:subscription_product, user: seller, price_cents: 1000) }
  let(:subscription) { create(:subscription, user: buyer, link: product) }
  let(:purchase) { subscription.original_purchase }

  before do
    # Set up purchase with VAT charges
    purchase.update!(
      gumroad_tax_cents: 200,
      was_purchase_taxable: true,
      purchase_state: "successful"
    )

    # Create sales tax info
    create(:purchase_sales_tax_info,
           purchase: purchase,
           country_code: "IE")
  end

  describe "POST /purchases/:id/apply_vat_id_to_subscription" do
    context "with valid VAT ID" do
      it "applies VAT ID to subscription" do
        expect(subscription).to receive(:apply_vat_id_retroactively!).with("IE6388047V").and_return(true)

        post apply_vat_id_to_subscription_path(purchase.external_id),
             params: { business_vat_id: "IE6388047V" }

        expect(response).to redirect_to(purchase_path(purchase.external_id))
        expect(flash[:notice]).to include("VAT ID has been applied to your subscription")
      end
    end

    context "with invalid VAT ID" do
      it "shows error message" do
        post apply_vat_id_to_subscription_path(purchase.external_id),
             params: { business_vat_id: "INVALID_VAT_ID" }

        expect(response).to redirect_to(purchase_path(purchase.external_id))
        expect(flash[:alert]).to include("Invalid VAT ID format")
      end
    end

    context "with blank VAT ID" do
      it "shows error message" do
        post apply_vat_id_to_subscription_path(purchase.external_id),
             params: { business_vat_id: "" }

        expect(response).to redirect_to(purchase_path(purchase.external_id))
        expect(flash[:alert]).to include("VAT ID is required")
      end
    end

    context "when purchase is not part of subscription" do
      let(:standalone_purchase) { create(:purchase, user: buyer, link: product) }

      it "shows error message" do
        post apply_vat_id_to_subscription_path(standalone_purchase.external_id),
             params: { business_vat_id: "IE6388047V" }

        expect(response).to redirect_to(purchase_path(standalone_purchase.external_id))
        expect(flash[:alert]).to include("This purchase is not part of a subscription")
      end
    end

    context "when purchase is not found" do
      it "redirects to root with error" do
        post apply_vat_id_to_subscription_path("invalid_id"),
             params: { business_vat_id: "IE6388047V" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Purchase not found")
      end
    end
  end
end
