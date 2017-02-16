class SessionsController < Devise::SessionsController

  def create
    redirect_to root_path
  end
end
