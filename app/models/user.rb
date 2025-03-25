# frozen_string_literal: true

class User
  attr_reader :userid, :account, :role

  thread_mattr_accessor :current

  def initialize(opts)
    @userid = opts[:userid]
    @account = opts[:account]
    @role = opts[:role]
  end
end
