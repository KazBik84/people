class UserIndexPage
  def serialized_projects
    ActiveModel::ArraySerializer.new(projects, each_serializer: UserProjectSerializer).as_json
  end

  def serialized_users
    ActiveModel::ArraySerializer.new(users, each_serializer: UserSerializer).as_json
  end

  def serialized_memberships
    memberships.as_json
  end

  def serialized_roles
    roles.as_json
  end

  private

  def projects
    @projects ||= Project.where(archived: false)
  end

  def users
    @users ||= User.includes(:primary_roles).active.by_last_name
  end

  def memberships
    @memberships ||= Membership.where(project_id: projects.ids)
  end

  def roles
    @roles ||= Role.all
  end
end
