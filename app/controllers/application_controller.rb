# Base class inherited by all controllers.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # "Stub" root route, used primarily to test out test harness
  def index
    render inline: <<-HEREDOC
      <p>Welcome aboard</p>
      <script>
        document.write("Javascript added here");
      </script>
    HEREDOC
  end
end
