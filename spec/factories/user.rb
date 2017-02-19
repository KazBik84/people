FactoryGirl.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { Devise.friendly_token[0, 20] }
    gh_nick { Faker::Name.first_name }
    employment { 100 }
    without_gh false
    gravatar { File.open(Rails.root.join('spec', 'fixtures', 'gravatar', 'gravatar.jpg')) }
    user_notes { Faker::Lorem.sentence }

    factory :user_deleted do
      deleted_at Time.now
    end

    trait :archived do
      archived true
    end

    trait :admin do
      admin true
    end

    trait :junior do
      positions { [create(:position, :primary, role: create(:junior_role))] }
    end

    trait :intern do
      positions { [create(:position, :primary, role: create(:intern_role))] }
    end

    trait :developer do
      positions { [create(:position, :primary, role: create(:dev_role))] }
    end
  end

  factory :plain_user, class: "User" do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password 'netguru123'
    without_gh true
    factory :qa_user do
      positions { [create(:position, :primary, role: create(:qa_role))] }
    end
    factory :pm_user do
      positions { [create(:position, :primary, role: create(:pm_role))] }
    end
  end

  factory :developer_in_project, parent: :user do
    positions { [create(:position, :primary, role: create(:dev_role))] }

    transient do
      project { create(:project) }
      membership_due_date nil
    end

    after(:create) do |user, evaluator|
      create(:membership, :billable,
        user: user,
        project: evaluator.project,
        ends_at: evaluator.membership_due_date
      )
    end

    trait :with_project_scheduled do
      transient do
        scheduled_project nil
        scheduled_membership_start nil
        booked false
      end

      after(:create) do |user, evaluator|
        create(:membership, :without_end, :billable,
          {
            user: user,
            project: evaluator.scheduled_project,
            starts_at: evaluator.scheduled_membership_start,
            booked: evaluator.booked
          }.reject { |_, v| v.nil? }
        )
      end
    end

    trait :with_project_scheduled_with_due_date do
      transient do
        scheduled_project nil
        booked false
      end

      after(:create) do |user, evaluator|
        create(:membership, :billable,
          {
            user: user,
            project: evaluator.scheduled_project,
            booked: evaluator.booked
          }.reject { |_, v| v.nil? }
        )
      end
    end
  end
end
