# Global helper functions
module ApplicationHelper
  def pp_time(time)
    time.strftime Rails.configuration.x.time_display_fmt
  end
end
