class UserDecorator < Draper::Decorator

  # 60 seconds * 60 minutes * 24 hours * 30.44 days in a month on average
  DAYS_IN_MONTH = 60 * 60 * 24 * 30.44

  decorates :user
  decorates_association :memberships, scope: :only_active
  decorates_association :positions
  delegate_all

  def name
    "#{last_name} #{first_name}"
  end

  def primary_role_name
    primary_role.present? ? primary_role.name : ''
  end

  def gravatar_image(options = {})
    size = options.delete(:size)
    h.image_tag gravatar_url(size), options
  end

  def skype_link
    return unless skype?

    h.link_to "skype:#{skype}?userinfo" do
      h.fa_icon('skype')
    end
  end

  def skype_nick
    @skype_nick ||= skype.presence || 'No skype'
  end

  def phone_number
    @phone_number ||= phone.presence || 'No phone'
  end

  def info
    projects = project_names.join(', ')
    "#{name}\n#{phone_number}\n#{email}\n#{skype_nick}\n#{projects}"
  end

  def months_in_current_project
    longest_current_membership = current_memberships.min_by { |m| m.starts_at }
    return 0 if longest_current_membership.nil?
    (Time.now - longest_current_membership.starts_at.to_time) / DAYS_IN_MONTH
  end

  def flat_memberships
    FlatMembershipsBuilder.new(self).build
  end

  def project_names
    model.projects.map(&:name).uniq
  end

  def projects_json(membership)
    membership.map { |c_ms| { project: c_ms.project, billable: c_ms.billable, membership: c_ms } }
  end

  def next_projects_json
    @next_projects_json ||= projects_json(next_memberships)
  end

  def booked_projects_json
    @booked_projects_json ||= projects_json(booked_memberships)
  end

  def potential_projects_json
    @potential_projects_json ||= projects_json(potential_memberships)
  end

  def current_projects_with_memberships_json
    @current_projects_with_memberships_json ||= projects_json(current_memberships)
  end

  def previous_projects_json
    @previous_projects_json ||= projects_json(previous_memberships)
  end

  def skills_history_header
    object == h.current_user ? 'Your' : "#{first_name} #{last_name}"
  end
end
