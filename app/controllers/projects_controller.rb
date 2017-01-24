class ProjectsController < ApplicationController
  include Shared::RespondsController

  before_filter :authenticate_admin!, except: [:show]

  expose_decorated(:project, attributes: :project_params)

  def create
    if project.save
      SendMailWithUserJob.perform_async(ProjectMailer, :created, project, current_user.id)
      respond_on_success project
    else
      respond_on_failure project.errors
    end
  end

  def show
    gon.project = project
    gon.events = get_events
  end

  def update
    update_associated_memberships
    archive_project if project.archived_changed?(from: false, to: true)

    if project.save
      respond_on_success project
    else
      respond_on_failure project.errors
    end
  end

  def destroy
    if project.destroy
      redirect_to(dashboard_index_path, notice: I18n.t('projects.success', type: 'delete'))
    else
      redirect_to(dashboard_index_path, alert: I18n.t('projects.error', type: 'delete'))
    end
  end

  private

  def update_associated_memberships
    Memberships::UpdateStays.new(project.id, project_params[:membership_ids]).call
    update_booked_memberships
  end

  def archive_project
    Projects::EndCurrentMemberships.new(project).call
    project.end_at = Date.current.end_of_day
  end

  def update_booked_memberships
    if project.potential_changed?(from: true, to: false)
      Memberships::UpdateBooked.new(params[:project][:membership_ids]).call(false)
    end
  end

  def project_params
    params
      .require(:project)
      .permit(
        :name, :starts_at, :end_at, :archived, :potential,
        :synchronize, :kickoff, :project_type, :toggl_bookmark, :internal,
        :maintenance_since, :color, :sf_id,
        membership_ids: [],
        memberships_attributes: [:id, :stays, :user_id, :role_id, :starts_at, :billable]
      )
  end

  def get_events
    project.memberships.map do |m|
      event = { text: m.user.decorate.name, startDate: m.starts_at.to_date }
      event[:user_id] = m.user.id.to_s
      event[:endDate] = m.ends_at.to_date if m.ends_at
      event[:billable] = m.billable
      event
    end
  end
end
