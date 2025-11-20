# frozen_string_literal: true

require "spec_helper"
require "shared_examples/authorize_called"
require "shared_examples/sellers_base_controller_concern"
require "inertia_rails/rspec"

describe EmailsController, type: :controller, inertia: true do
  it_behaves_like "inherits from Sellers::BaseController"

  render_views

  let(:seller) { create(:user) }

  include_context "with user signed in as admin for seller"

  describe "GET index" do
    it_behaves_like "authorize called for action", :get, :index do
      let(:record) { Installment }
    end

    it "redirects to the scheduled tab if there are scheduled installments" do
      create(:scheduled_installment, seller:)

      get :index

      expect(response).to redirect_to("/emails/scheduled")
    end

    it "redirects to the published tab otherwise" do
      get :index

      expect(response).to redirect_to("/emails/published")
    end
  end

  describe "GET published" do
    it_behaves_like "authorize called for action", :get, :published do
      let(:record) { Installment }
    end

    it "renders the published tab via Inertia" do
      create(:published_installment, seller:)

      get :published

      expect(response).to be_successful
      expect(inertia).to render_component("Emails/Published/index")
      expect(inertia.props[:installments]).to be_an(Array)
    end
  end

  describe "GET scheduled" do
    it_behaves_like "authorize called for action", :get, :scheduled do
      let(:record) { Installment }
    end

    it "renders the scheduled tab via Inertia" do
      create(:scheduled_installment, seller:)

      get :scheduled

      expect(response).to be_successful
      expect(inertia).to render_component("Emails/Scheduled/index")
      expect(inertia.props[:installments]).to be_an(Array)
    end
  end

  describe "GET drafts" do
    it_behaves_like "authorize called for action", :get, :drafts do
      let(:record) { Installment }
    end

    it "renders the drafts tab via Inertia" do
      create(:installment, seller:, published_at: nil, ready_to_publish: false)

      get :drafts

      expect(response).to be_successful
      expect(inertia).to render_component("Emails/Drafts/index")
      expect(inertia.props[:installments]).to be_an(Array)
    end
  end

  describe "GET new" do
    it_behaves_like "authorize called for action", :get, :new do
      let(:record) { Installment }
    end

    it "renders the new email form" do
      get :new

      expect(response).to be_successful
      expect(inertia).to render_component("Emails/New/index")
      expect(inertia.props[:context]).to be_present
    end
  end

  describe "GET edit" do
    let!(:installment) { create(:installment, seller:) }

    it_behaves_like "authorize called for action", :get, :edit do
      let(:record) { installment }
      let(:request_params) { { id: installment.external_id } }
    end

    it "renders the edit email form" do
      get :edit, params: { id: installment.external_id }

      expect(response).to be_successful
      expect(inertia).to render_component("Emails/Edit/index")
      expect(inertia.props[:installment]).to be_present
    end
  end
end
