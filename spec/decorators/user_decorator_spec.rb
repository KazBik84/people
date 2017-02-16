require 'spec_helper'

describe UserDecorator do
  def time(year, month, day)
    Time.new(year, month, day)
  end

  let(:team) { create(:team) }
  let(:user) { create(:user, teams: [team], team_join_time: 6.days.ago) }
  let(:user_without_team) { create(:user) }
  subject { user.decorate }

  describe '#project_names' do
    let!(:membership) { create(:membership, user: user) }

    before { subject.reload }

    it { expect(subject.project_names).to eq [membership.project.name] }
  end

  describe '#gravatar_image' do
    it { expect(subject.gravatar_image).to include(subject.gravatar_url.to_s) }
  end

  describe '#skype_link' do
    before do
      user.skype = 'skype_login'
    end
    it { expect(subject.skype_link).to include('skype_login') }
  end

  describe '#current_projects_with_memberships_json' do
    let!(:project) { create(:project, name: 'google') }

    it "returns projects list to include 'google' project" do
      create(
        :membership,
        starts_at: 2.weeks.ago,
        ends_at: 2.weeks.from_now,
        user: subject,
        project: project
      )
      expect(subject.current_projects_with_memberships_json.first[:project]).to eq project
    end

    it 'returns no projects' do
      create(
        :membership,
        starts_at: 2.weeks.ago,
        ends_at: Date.yesterday,
        user: subject,
        project: project
      )
      expect(subject.current_projects_with_memberships_json).to be_empty
    end

    it 'returns projects array to include 2 projects' do
      project = create(
        :project,
        starts_at: time(2010, 12, 1),
        end_at: nil
      )
      project2 = create(
        :project,
        starts_at: time(2010, 12, 1),
        end_at: nil
      )
      create(
        :membership,
        project: project,
        starts_at: time(2011, 1, 1),
        ends_at: time(2012, 1, 1),
        user: subject,
        role: create(:role, name: 'pm1')
      )
      create(
        :membership,
        project: project2,
        starts_at: time(2012, 1, 2),
        ends_at: 1.year.from_now,
        user: subject,
        role: create(:role, name: 'pm2')
      )
      create(
        :membership_without_ends_at,
        project: project,
        starts_at: time(2013, 1, 5),
        user: subject,
        role: create(:role, name: 'pm3')
      )
      expect(subject.current_projects_with_memberships_json.count).to eq 2
    end
  end

  describe '#potential_projects_json' do
    let!(:project_potential) { create(:project, potential: true) }

    context 'when user belongs to potential project' do
      before do
        create(:membership, starts_at: 2.days.ago, ends_at: nil,
                            user: subject, project: project_potential)
      end

      it 'returns potential project' do
        expect(subject.potential_projects_json.first[:project]).to eq project_potential
      end
    end

    context 'when user used to belong to potential project' do
      before do
        create(:membership, starts_at: 10.days.ago, ends_at: 5.days.ago,
                            user: subject, project: project_potential)
      end

      it 'returns no potential project' do
        expect(subject.potential_projects_json).to be_empty
      end
    end
  end

  describe '#next_projects_json' do
    let!(:project_current) { create(:project, name: 'google') }
    let!(:project_next) { create(:project, name: 'facebook') }

    before { Timecop.freeze(Time.local(2013, 12, 1)) }
    after { Timecop.return }

    context 'when user has unstarted membership' do
      before do
        create(:membership, starts_at: time(2012, 1, 1), ends_at: nil,
                            user: subject, project: project_current)
        create(:membership, starts_at: time(2013, 12, 15), ends_at: nil,
                            user: subject, project: project_next)
      end

      it 'returns next project' do
        expect(subject.next_projects_json.first[:project].name).to eq project_next.name
      end
    end
  end
end
