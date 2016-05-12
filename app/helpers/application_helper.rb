# Global helper functions
module ApplicationHelper
  # Generic print function for date-times in tool
  def pp_time(time)
    time.strftime Rails.configuration.x.time_display_fmt
  end

  # @param run [Run] Run that produced this output
  # @param eadid [String, nil] of individual EAD, or nil for zipped resultset
  # @return [String] absolute path to an output XML or .zip
  def output_path(run, eadid = nil)
    "/output/#{run.id.to_s}/#{eadid ? "#{eadid}.xml" : 'out.zip'}"
  end

  # @param run [Run] Run that this input belongs to
  # @return [String] absolute path to an input .zip
  def input_path(run)
    "/input/#{run.id.to_s}/input.zip"
  end
end
