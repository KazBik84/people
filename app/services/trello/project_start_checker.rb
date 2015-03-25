module Trello
  class ProjectStartChecker
    def initialize
      get_cards
    end

    def run!
      @cards.each do |card|
        card_label_names(card).each do |label|
          create_membership_for_user(user_from_card(card), label)
        end
      end
    end

    private

    def card_label_names(card)
      card.card_labels.map { |label| label['name'] }
    end

    def create_membership_for_user(user, project_name)
      UserMembershipRepository.new(user).create(
        project: project_from_label(project_name),
        starts_at: Date.yesterday,
        role: Role.first,
        billable: false
      )
    end

    def get_cards
      board = Trello::Board.find AppConfig.trello.schedule_board_id
      @cards = board.cards
    end

    def project_from_label(label)
      ProjectsRepository.new.find_or_create_by_name label
    end

    def user_from_card(card)
      attrs = {
        first_name: card.name.split[0],
        last_name:  card.name.split[1]
      }
      User.find_by attrs
    end
  end
end