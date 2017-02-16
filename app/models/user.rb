class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :trackable, :validatable

  mount_uploader :gravatar, GravatarUploader

  has_many :memberships, -> { order(:ends_at) }, dependent: :destroy
  has_many :notes
  has_many :positions
  has_many :projects, through: :memberships
  has_many :roles, through: :positions
  has_many :user_skill_rates
  has_many :skills, through: :user_skill_rates
  belongs_to :contract_type
  belongs_to :location
  belongs_to :primary_role, class_name: 'Role'
  has_and_belongs_to_many :abilities
  has_and_belongs_to_many :teams

  # ugly optimization hack
  has_many :current_memberships, -> { active.unfinished.started }, anonymous_class: Membership
  has_many :potential_memberships, -> { potential.unfinished }, anonymous_class: Membership
  has_many :next_memberships, -> { next_memberships }, anonymous_class: Membership
  has_many :previous_memberships, -> {
    where('ends_at < ?', Time.zone.now)
  }, anonymous_class: Membership
  has_many :booked_memberships, -> {
    where(booked: true)
      .where('memberships.ends_at IS NULL OR memberships.ends_at > ?', Time.current)
      .order('memberships.ends_at ASC NULLS FIRST, id ASC')
  }, anonymous_class: Membership
  has_one :last_membership, -> {
    active
      .unfinished
      .started
      .order('memberships.ends_at DESC NULLS FIRST')
  }, anonymous_class: Membership
  has_one :longest_current_membership, -> {
    active
      .unfinished
      .started
      .order('memberships.ends_at DESC NULLS FIRST, memberships.starts_at ASC')
  }, anonymous_class: Membership
  has_many :primary_roles, -> {
    joins(:positions)
      .where(positions: { primary: true })
      .group('roles.id')
      .group('positions.starts_at')
  }, through: :positions, source: :role

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :employment, inclusion: { in: 0..200, message: 'must be between 0-200' }
  validates :phone, phone_number: true, length: { maximum: 16 }, allow_blank: true
  validates :archived, inclusion: { in: [true, false] }
  validates :commitment, numericality: { less_than_or_equal_to: 40 }, allow_blank: true

  scope :by_name, -> {
    includes(:primary_role, :memberships, positions: [:role])
      .order(:first_name, :last_name)
  }
  scope :by_last_name, -> { order(:last_name, :first_name) }
  scope :available, -> { where.not(id: unavailable.select(:id)) }
  scope :unavailable, -> do
    joins(memberships: :project).where("lower(projects.name) = 'unavailable'")
      .where(
        '(memberships.ends_at IS NULL) OR (memberships.ends_at >= ?)',
        DateTime.current.beginning_of_day
      )
      .merge(Membership.started)
  end
  scope :active, -> { where(archived: false) }
  scope :technical, -> { joins(:positions).where(positions: { role_id: Role.technical.pluck(:id) }) }
  scope :technical_active, -> { where(archived: false) }
  scope :roles, -> (roles) { joins(:positions).where(positions: { role: roles, primary: true }) }
  scope :contract_users, -> (contract_type) {
    ContractType.where(name: contract_type).first.try(:users)
  }
  scope :without_team, -> { where(team: nil) }
  scope :booked, -> do
    joins(:memberships).where(memberships: { booked: true })
      .where('memberships.ends_at IS NULL OR memberships.ends_at > ?', Time.current)
  end
  scope :not_booked, -> { where.not(id: booked.select(:id)) }
  scope :with_scheduled_memberships, -> do
    joins(memberships: :project).where('memberships.starts_at > ?', Time.current)
      .where.not(projects: { id: Project.unavailable.select(:id) })
  end
  scope :with_scheduled_commercial_memberships, -> do
    with_scheduled_memberships.merge(Project.commercial.not_maintenance)
  end
  scope :without_scheduled_commercial_memberships, -> do
    where.not(id: with_scheduled_commercial_memberships.select(:id))
  end
  scope :with_memberships_and_projects, -> do
    joins(memberships: :project)
  end
  scope :with_current_memberships, -> do
    with_memberships_and_projects
      .where(memberships: { id: Membership.active.unfinished.started.select(:id) })
  end
  scope :without_excluded_projects, lambda {
    joins(memberships: :project).where('projects.name NOT IN (?)', Project::EXCLUDED_PROJECTS)
  }
  scope :membership_between, lambda { |start_date, end_date|
    joins(memberships: :role)
      .where(
        '(memberships.starts_at <= ? AND (memberships.ends_at >= ? OR memberships.ends_at IS NULL))
          OR
          (memberships.starts_at <= ? AND (memberships.ends_at >= ? OR memberships.ends_at IS NULL))
          OR
          (memberships.starts_at >= ? AND memberships.ends_at <= ?)',
        start_date,
        start_date,
        end_date,
        end_date,
        start_date,
        end_date)
  }
  scope :billable_roles_between, lambda { |roles, start_date, end_date|
    membership_between(start_date, end_date)
      .where('roles.name IN (?) AND memberships.billable = true', roles)
      .without_excluded_projects.distinct.order(:last_name)
  }
  scope :roles_between, lambda { |roles, start_date, end_date|
    membership_between(start_date, end_date)
      .where('roles.name IN (?)', roles)
      .without_excluded_projects.distinct.order(:last_name)
  }
  scope :developers_in_internals_between, lambda { |roles, start_date, end_date|
    membership_between(start_date, end_date)
      .where('roles.name IN (?) AND project_internal = true', roles)
      .without_excluded_projects.distinct.order(:last_name)
  }
  scope :non_billable_in_commercial_projects_between, lambda { |roles, start_date, end_date|
    membership_between(start_date, end_date)
      .where(
        'roles.name IN (?) AND project_potential = false AND project_archived = false
          AND project_internal = false AND memberships.billable = false',
        roles).without_excluded_projects.distinct.order(:last_name)
  }

  before_save :end_memberships

  def self.cache_key
    maximum(:updated_at)
  end

  def primary_role
    super || NullRole.new
  end

  def github_connected?
    gh_nick.present? || without_gh == true
  end

  def has_current_projects?
    current_memberships.present?
  end

  def has_next_projects?
    next_memberships.present?
  end

  def has_potential_projects?
    potential_memberships.present?
  end

  def end_memberships
    memberships.each(&:end_now!) if archived_change && archived_change.last
  end

  def user_memberships_repository
    @user_memberships_repository ||= UserMembershipsRepository.new(self)
  end

  def leader?
    Team.any? { |team| team.leader == self }
  end

  def talent?
    roles.pluck(:name).include?('talent')
  end

  def rated_skills
    ::Skill
      .joins(user_skill_rates: :contents)
      .where('user_skill_rate_contents.created_at = (SELECT MAX(user_skill_rate_contents.created_at) FROM user_skill_rate_contents WHERE user_skill_rates.id = user_skill_rate_contents.user_skill_rate_id)')
      .where('user_skill_rates.user_id' => self.id)
      .where('user_skill_rate_contents.rate > 0')
  end

  def non_rated_skills
    ::Skill
      .joins(user_skill_rates: :contents)
      .where('user_skill_rate_contents.created_at = (SELECT MAX(user_skill_rate_contents.created_at) FROM user_skill_rate_contents WHERE user_skill_rates.id = user_skill_rate_contents.user_skill_rate_id)')
      .where('user_skill_rates.user_id' => self.id)
      .where('user_skill_rate_contents.rate = 0')
  end
end
