class RunsController < ApplicationController
  def index
    @runs = Run.order(created_at: :desc)
  end

  def show
    @run = Run.includes(finding_aid_versions: {finding_aid: :repository}).find(params[:id])
  end

  def run_params
    params.require(:id)
  end
end
