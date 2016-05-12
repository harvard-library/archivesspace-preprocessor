class FindingAidVersionsController < ApplicationController

  def show
    @fav = FindingAidVersion.includes(:finding_aid).find_by(digest: params[:digest])
    respond_to do |f|
      f.xml
      f.html
    end
  end

  # @visibility private
  def finding_aid_version_params
    params.require(:digest)
  end
end
