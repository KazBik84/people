module Api::V2
  class UsersController < Api::ApiController
    expose_decorated(:users) { User.active.includes(:primary_role, :primary_roles, memberships: [:project, :role]) }

    def index
      render json: users, each_serializer: UserSerializer, root: false
    end
  end
end
