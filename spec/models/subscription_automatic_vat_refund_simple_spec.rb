# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Subscription Automatic VAT Refund - Simple Tests", type: :model do
  let(:seller) { create(:user) }
  let(:buyer) { create(:user) }
  let(:product) { create(:subscription_product, user: seller, price_cents: 1000) }
  let(:subscription) { create(:subscription, user: buyer, link: product) }

  describe "#validate_vat_id" do
    let(:purchase) { double("Purchase") }
    let(:tax_info) { double("PurchaseSalesTaxInfo", country_code: "IE") }

    before do
      allow(purchase).to receive(:purchase_sales_tax_info).and_return(tax_info)
    end

    it "validates Irish VAT ID correctly" do
      # Mock the VatValidationService to return true for a valid Irish VAT ID
      allow(VatValidationService).to receive(:new).with("IE6388047V").and_return(double(process: true))

      result = subscription.validate_vat_id("IE6388047V", purchase)
      expect(result).to be true
    end

    it "returns false for invalid VAT ID" do
      # Mock the VatValidationService to return false for an invalid VAT ID
      allow(VatValidationService).to receive(:new).with("INVALID_VAT_ID").and_return(double(process: false))

      result = subscription.validate_vat_id("INVALID_VAT_ID", purchase)
      expect(result).to be false
    end
  end

  describe "#get_business_vat_id_for_purchase" do
    let(:purchase) { double("Purchase") }
    let(:tax_info) { double("PurchaseSalesTaxInfo", business_vat_id: "IE6388047V") }

    before do
      allow(purchase).to receive(:purchase_sales_tax_info).and_return(tax_info)
      allow(subscription).to receive(:original_purchase).and_return(nil)
    end

    it "returns VAT ID from purchase sales tax info" do
      result = subscription.get_business_vat_id_for_purchase(purchase)
      expect(result).to eq("IE6388047V")
    end

    it "returns nil when no VAT ID is present" do
      allow(tax_info).to receive(:business_vat_id).and_return(nil)
      allow(purchase).to receive(:purchase_sales_tax_info).and_return(nil)
      allow(purchase).to receive(:id).and_return(123)

      # Mock the complex chain: purchases.successful.where.not(id: purchase.id).last
      previous_purchase = double("previous_purchase")
      allow(previous_purchase).to receive(:purchase_sales_tax_info).and_return(nil)
      not_mock = double("not")
      allow(not_mock).to receive(:last).and_return(previous_purchase)
      where_mock = double("where")
      allow(where_mock).to receive(:not).and_return(not_mock)
      successful_mock = double("successful")
      allow(successful_mock).to receive(:where).and_return(where_mock)
      purchases_mock = double("purchases")
      allow(purchases_mock).to receive(:successful).and_return(successful_mock)
      allow(subscription).to receive(:purchases).and_return(purchases_mock)

      result = subscription.get_business_vat_id_for_purchase(purchase)
      expect(result).to be_nil
    end
  end

  describe "#process_automatic_vat_refund" do
    let(:purchase) { double("Purchase") }

    before do
      allow(purchase).to receive(:successful?).and_return(true)
      allow(purchase).to receive(:gumroad_tax_cents).and_return(200)
      allow(purchase).to receive(:gumroad_tax_refundable_cents).and_return(200)
      allow(purchase).to receive(:id).and_return(123)
      allow(subscription).to receive(:get_business_vat_id_for_purchase).with(purchase).and_return("IE6388047V")
      allow(subscription).to receive(:validate_vat_id).with("IE6388047V", purchase).and_return(true)
    end

    it "processes VAT refund when conditions are met" do
      expect(purchase).to receive(:refund_gumroad_taxes!).with(
        refunding_user_id: GUMROAD_ADMIN_ID,
        note: "Automatic VAT refund for recurring subscription",
        business_vat_id: "IE6388047V"
      ).and_return(true)

      subscription.process_automatic_vat_refund(purchase)
    end

    it "does not process refund when purchase is not successful" do
      allow(purchase).to receive(:successful?).and_return(false)

      expect(purchase).not_to receive(:refund_gumroad_taxes!)
      subscription.process_automatic_vat_refund(purchase)
    end

    it "does not process refund when no VAT charges exist" do
      allow(purchase).to receive(:gumroad_tax_cents).and_return(0)

      expect(purchase).not_to receive(:refund_gumroad_taxes!)
      subscription.process_automatic_vat_refund(purchase)
    end

    it "does not process refund when no VAT ID is available" do
      allow(subscription).to receive(:get_business_vat_id_for_purchase).with(purchase).and_return(nil)

      expect(purchase).not_to receive(:refund_gumroad_taxes!)
      subscription.process_automatic_vat_refund(purchase)
    end
  end
end
