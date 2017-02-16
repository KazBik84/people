class WelcomeController < ApplicationController
  skip_before_filter :authenticate_user!, only: :index
  skip_before_render :message_to_js

  def index; end

end
