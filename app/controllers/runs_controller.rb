class RunsController < ApplicationController
  # Root page of application
  def index
    @runs = Run.order(created_at: :desc)
  end

  # An individual run, lists and provides downloads of finding aids
  def show
    @run = Run.includes(finding_aid_versions: {finding_aid: :repository}).find(params[:id])
  end

  # @visibility private
  def run_params
    params.require(:id)
  end
end
