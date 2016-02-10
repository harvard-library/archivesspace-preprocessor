class ReportsController < ApplicationController
  # TODO: DOCS, POSSIBLY REWRITE AFTER SOME DESIGN OR SOMETHING
  def issues_per_repo
    @data = Report.issues_per_repo
  end
end
