# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ResponseHelper

  before_action :setup_user

  def setup_user
    userid, account, role = auth_headers
    User.current = User.new({userid: userid, account: account, role: role})
  end

  def operator_required
    unless User.current.role == "operator"
      return forbidden("You're not authorized to perform action.")
    end
  end

  private

  def auth_headers
    userid = request.headers['x-auth-user']
    group = request.headers['x-auth-group']
    account = ""
    roles = ""

    unless group
      account = request.headers['x-auth-account']
      role = request.headers['x-auth-role']
    else
      account, role = group.split('.')
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
