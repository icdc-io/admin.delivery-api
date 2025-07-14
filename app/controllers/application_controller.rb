# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ApiExceptionsHandler
  include ResponseHelper

  before_action :setup_user
  around_action :handle_exceptions

  def setup_user
    userid, account, role = auth_headers
    User.current = User.new({ userid: userid, account: account, role: role })
  end

  def operator_required
    return if User.current.role == 'operator'

    forbidden("You're not authorized to perform action.")
  end

  private

  def auth_headers
    userid = request.headers['x-auth-user']
    group = request.headers['x-auth-group']
    account = ''

    if group
      account, role = group.split('.')
    else
      account = request.headers['x-auth-account']
      role = request.headers['x-auth-role']
    end

    role = setup_role(account, role)

    [userid, account, role]
  end

  def setup_role(account, role)
    return role unless %w[operator admin].include?(role)

    if ENV.fetch('OPERATOR_GROUP') == "#{account}.#{role}"
      'operator'
    else
      'admin'
    end
  end
end
