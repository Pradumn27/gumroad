# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Subscription Automatic VAT Refund", type: :model do
  let(:seller) { create(:user) }
  let(:buyer) { create(:user) }
  let(:product) { create(:subscription_product, user: seller, price_cents: 1000) }
  let(:subscription) { create(:subscription, user: buyer, link: product) }
  let(:original_purchase) { @purchase }

  before do
    # Create a simple purchase for testing
    @purchase = create(:purchase,
                      link: product,
                      purchaser: buyer,
                      email: buyer.email,
                      full_name: "Test User",
                      subscription: subscription,
                      is_original_subscription_purchase: true,
                      gumroad_tax_cents: 200,
                      was_purchase_taxable: true,
                      purchase_state: "successful")

    # Create sales tax info with VAT ID
    create(:purchase_sales_tax_info,
           purchase: @purchase,
           business_vat_id: "IE6388047V",
           country_code: "IE")
  end

  describe "#process_automatic_vat_refund" do
    context "when purchase has VAT charges and valid VAT ID" do
      it "automatically refunds VAT for recurring charges" do
        # Create a new recurring purchase
        recurring_purchase = subscription.build_purchase
        recurring_purchase.update!(
          gumroad_tax_cents: 200,
          was_purchase_taxable: true,
          purchase_state: "successful"
        )

        # Mock the refund method
        expect(recurring_purchase).to receive(:refund_gumroad_taxes!).with(
          refunding_user_id: GUMROAD_ADMIN_ID,
          note: "Automatic VAT refund for recurring subscription",
          business_vat_id: "IE6388047V"
        ).and_return(true)

        # Process the automatic VAT refund
        subscription.process_automatic_vat_refund(recurring_purchase)
      end
    end

    context "when purchase has no VAT charges" do
      it "does not process refund" do
        recurring_purchase = subscription.build_purchase
        recurring_purchase.update!(
          gumroad_tax_cents: 0,
          was_purchase_taxable: false,
          purchase_state: "successful"
        )

        expect(recurring_purchase).not_to receive(:refund_gumroad_taxes!)
        subscription.process_automatic_vat_refund(recurring_purchase)
      end
    end

    context "when no valid VAT ID exists" do
      it "does not process refund" do
        # Remove VAT ID from original purchase
        original_purchase.purchase_sales_tax_info.update!(business_vat_id: nil)

        recurring_purchase = subscription.build_purchase
        recurring_purchase.update!(
          gumroad_tax_cents: 200,
          was_purchase_taxable: true,
          purchase_state: "successful"
        )

        expect(recurring_purchase).not_to receive(:refund_gumroad_taxes!)
        subscription.process_automatic_vat_refund(recurring_purchase)
      end
    end
  end

  describe "#apply_vat_id_retroactively!" do
    context "with valid VAT ID" do
      it "applies VAT ID to subscription and refunds original purchase" do
        # Mock the refund method
        expect(original_purchase).to receive(:refund_gumroad_taxes!).with(
          refunding_user_id: GUMROAD_ADMIN_ID,
          note: "Retroactive VAT ID application for subscription",
          business_vat_id: "DE123456789"
        ).and_return(true)

        result = subscription.apply_vat_id_retroactively!("DE123456789")

        expect(result).to be true
        expect(original_purchase.purchase_sales_tax_info.reload.business_vat_id).to eq("DE123456789")
      end
    end

    context "with invalid VAT ID" do
      it "returns false and does not apply VAT ID" do
        result = subscription.apply_vat_id_retroactively!("INVALID_VAT_ID")

        expect(result).to be false
        expect(original_purchase.purchase_sales_tax_info.reload.business_vat_id).to be_nil
      end
    end
  end

  describe "#get_business_vat_id_for_purchase" do
    it "returns VAT ID from purchase sales tax info" do
      recurring_purchase = subscription.build_purchase
      recurring_purchase.purchase_sales_tax_info = create(:purchase_sales_tax_info,
                                                          purchase: recurring_purchase,
                                                          business_vat_id: "FR12345678901")

      vat_id = subscription.get_business_vat_id_for_purchase(recurring_purchase)
      expect(vat_id).to eq("FR12345678901")
    end

    it "falls back to original purchase VAT ID" do
      recurring_purchase = subscription.build_purchase

      vat_id = subscription.get_business_vat_id_for_purchase(recurring_purchase)
      expect(vat_id).to eq("IE6388047V")
    end
  end
end
