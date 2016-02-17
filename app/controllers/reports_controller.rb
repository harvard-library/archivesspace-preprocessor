class ReportsController < ApplicationController
  # TODO: DOCS, POSSIBLY REWRITE AFTER SOME DESIGN OR SOMETHING
  def issues_per_repo
    render json: Report.issues_per_repo(Run.last)
  end

end
