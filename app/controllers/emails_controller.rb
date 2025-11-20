# frozen_string_literal: true

class EmailsController < Sellers::BaseController
  before_action :set_body_id_as_app
  before_action :authorize_installment, except: :edit
  before_action :set_installment, only: :edit

  layout "inertia"

  def index
    create_user_event("emails_view")
    redirect_to(default_tab_path, status: :moved_permanently)
  end

  def published
    render_tab(Installment::PUBLISHED)
  end

  def scheduled
    render_tab(Installment::SCHEDULED)
  end

  def drafts
    render_tab(Installment::DRAFT)
  end

  def new
    presenter = InstallmentPresenter.new(seller: current_seller)
    render inertia: "Emails/New/index",
           props: presenter.new_page_props(copy_from: params[:copy_from])
  end

  def edit
    presenter = InstallmentPresenter.new(seller: current_seller, installment: @installment)
    render inertia: "Emails/Edit/index", props: presenter.edit_page_props
  end

  private
    def render_tab(type)
      create_user_event("emails_view")
      render inertia: component_for(type), props: paginated_props_for(type)
    end

    def component_for(type)
      case type
      when Installment::PUBLISHED then "Emails/Published/index"
      when Installment::SCHEDULED then "Emails/Scheduled/index"
      else "Emails/Drafts/index"
      end
    end

    def paginated_props_for(type)
      PaginatedInstallmentsPresenter.new(
        seller: current_seller,
        type:,
        page: params[:page],
        query: params[:query],
      ).props
    end

    def default_tab_path
      if Installment.alive.not_workflow_installment.scheduled.where(seller: current_seller).exists?
        scheduled_emails_path
      else
        published_emails_path
      end
    end

    def authorize_installment
      authorize Installment
    end

    def set_installment
      @installment = current_seller.installments.alive.not_workflow_installment.find_by_external_id(params[:id])
      return e404 unless @installment

      authorize @installment
    end

    def set_title
      @title = "Emails"
    end
end
