# Collection of Ajax methods used to provide report info to client-side charting
class ReportsController < ApplicationController
  # TODO: DOCS, POSSIBLY REWRITE AFTER SOME DESIGN OR SOMETHING
  def issues_per_repo
    if run = Run.last
      render json: Report.issues_per_repo(run)
    else
      render json: {}
    end
  end

end
