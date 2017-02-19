class ApplicationController < ActionController::Base
  include BeforeRender
  include Pundit
  include Flip::ControllerFilters
  before_action :add_first_and_last_name_parms, if: :devise_controller?

  expose(:team_members) { fetch_team_members }

  protect_from_forgery with: :exception

  before_filter :authenticate_user!
  before_filter :set_gon_data

  before_render :message_to_js

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  decent_configuration do
    strategy DecentExposure::StrongParametersStrategy
  end

  def current_user
    @decorated_cu ||= super.decorate if super.present?
  end

  def current_user?
    user == current_user
  end

  private

  def add_first_and_last_name_parms
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit( :first_name, :last_name, :email, :password, :password_confirmation)}
  end

  def user_not_authorized
    redirect_to(
      request.referer || root_path,
      alert: 'You are not authorized to access this section.'
    )
  end

  def fetch_team_members
    team = Team.find_by(user_id: current_user.id)

    return [] if team.nil?
    UserDecorator.decorate_collection(
      TeamUsersRepository.new(team).subordinates
    )
  end

  def authenticate_admin!
    redirect_to root_path, alert: 'Permission denied! You have no rights to do this.'  unless current_user.admin?
  end

  def set_gon_data
    return unless current_user
    gon.rabl template: 'app/views/layouts/base.rabl', as: 'current_user'
  end

  def message_to_js
    @flashMessage = { notice: [], alert: [] }.with_indifferent_access
    flash.each do |name, msg|
      @flashMessage[name] << msg
    end
    gon.rabl template: 'app/views/layouts/flash.rabl', as: 'flash'
    # flash.clear
  end
end
