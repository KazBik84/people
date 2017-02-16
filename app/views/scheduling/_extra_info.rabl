node(:gravatar) { |user| user.gravatar_url(:thumb) }
node(:skype) { |user| user.skype_link }
node(:projects) { |user| user.current_projects_with_memberships_json }
node(:membership) { |user| user.last_membership }
node(:has_project) { |user| user.has_current_projects? }
node(:has_next_project) { |user| user.has_next_projects? }
node(:has_potential_project) { |user| user.has_potential_projects? }
node(:next_projects) { |user| user.next_projects_json }
node(:potential_projects) { |user| user.potential_projects_json }
node(:booked_projects) { |user| user.booked_projects_json }
node(root_object.category) { true }
node(:seconds_of_longest_current_membership) { |user| user.seconds_of_longest_current_membership }
node(:next_current_membership_ends_at) { |user| user.next_current_membership_ends_at }
