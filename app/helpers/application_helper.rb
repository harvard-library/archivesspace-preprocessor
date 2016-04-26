# Global helper functions
module ApplicationHelper
  def pp_time(time)
    time.strftime Rails.configuration.x.time_display_fmt
  end

  def output_path(run, eadid = nil)
    "/output/#{run.id.to_s}/#{eadid ? "#{eadid}.xml" : 'out.zip'}"
  end

  def input_path(run)
    "/input/#{run.id.to_s}/input.zip"
  end
end
