# frozen_string_literal: true

class UtmLinksController < Sellers::BaseController
  def index
    authorize UtmLink

    render inertia: "UtmLinks/index"
  end

  private
    def set_title
      @title = "UTM Links"
    end
end
