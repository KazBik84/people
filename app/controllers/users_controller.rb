class UsersController < ApplicationController
  include ContextFreeRepos
  before_filter :authenticate_admin!, only: :update, unless: -> { check_action }

  expose(:user) { users_repository.get params[:id] }
  expose(:users_index_page) { UserIndexPage.new }
  # FIXME: this is a bad way, we can't access repo from user model!
  expose(:user_memberships_repository) { UserMembershipsRepository.new(user) }
  expose(:user_positions_repository) { UserPositionsRepository.new(user) }
  expose(:user_projects_repository) do
    UserProjectsRepository.new(user, user_memberships_repository, projects_repository)
  end
  expose(:user_roles_repository) { UserRolesRepository.new(user) }
  expose(:new_membership_page) do
    UserShowPage::NewMembership.new(
      user: user,
      roles_repository: roles_repository,
      user_memberships_repository: user_memberships_repository,
      user_roles_repository: user_roles_repository,
      projects_repository: projects_repository
    )
  end
  expose(:user_show_page) do
    UserShowPage.new(
      user: user,
      projects_repository: projects_repository,
      user_projects_repository: user_projects_repository
    )
  end
  expose(:user_details_page) do
    UserShowPage::Details.new(
      user: user,
      roles_repository: roles_repository,
      locations_repository: locations_repository,
      abilities_repository: abilities_repository,
      user_positions_repository: user_positions_repository,
      contract_types_repository: contract_types_repository,
      user_roles_repository: user_roles_repository
    )
  end
  def update
    if UpdateUser.new(user, user_params, current_user).call
      info = { notice: t('users.show.updated') }
    else
      info = { alert: generate_errors }
    end
    respond_to do |format|
      format.html { redirect_to user, info }
      format.json { render json: user, root: false }
    end
  end

  def show
    gon.events = user_events
  end

  private

  def check_action
    user == current_user
  end

  def user_events
    UserEventsRepository.new(user_memberships_repository).all
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :employment,
      :commitment, :phone, :user_notes, :admin, :archived, :skype,
      :primary_role_id, :leader_team_id, :location_id, :contract_type_id, :team_id,
      :team_ids, team_ids: [], ability_ids: [], skill_ids: [], role_ids: [])
  end

  def generate_errors
    errors = []
    errors << user.errors.messages.map { |key, value| "#{key}: #{value[0]}" }.first
    errors.join
  end

  def months
    result = []
    result << { value: 0, text: 'Show all' }
    result << { value: 1, text: '1 month' }
    (2..12).each do |n|
      result << { value: n, text: "#{n} months" }
    end
    result
  end
end
