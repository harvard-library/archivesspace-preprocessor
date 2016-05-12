class FindingAidsController < ApplicationController
  def index
    @faids = FindingAid.all.order(eadid: :asc)
  end

  def show
    @faid = FindingAid.find_by(eadid: params[:eadid])
  end

  # @visibility private
  def finding_aid_params
    params.require(:eadid)
  end
end
