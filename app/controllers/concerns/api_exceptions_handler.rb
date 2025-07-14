# frozen_string_literal: true

module ApiExceptionsHandler
  extend ActiveSupport::Concern

  def handle_exceptions
    yield
  rescue RestClient::Exception => e
    handle_rest_client_error(e)
  rescue StandardError => e
    handle_standard_error(e)
  end

  private

  def handle_standard_error(exception)
    log_exception(exception)
    render json: { message: exception,
                   status: 500,
                   # TODO: leave this field for backward compatibility, remove it in future
                   data: exception }
    # end TODO
  end

  def handle_rest_client_error(exception)
    log_exception(exception)
    render json: { message: exception,
                   status: 500,
                   errors: rest_client_error_message(exception),
                   # TODO: leave this field for backward compatibility, remove it in future
                   data: exception }
    # end TODO
  end

  def log_exception(exception)
    Rails.logger.error exception.class.to_s
    Rails.logger.error { rest_client_error_message(exception) } if exception.response
    Rails.logger.error exception.to_s
    Rails.logger.error exception.backtrace.join("\n")
  end

  def rest_client_error_message(e)
    "#{e.response.request.method} #{e.response.request.url} failed (#{e.response.code}):
     #{JSON.parse(e.response.body)['message']}"
  end
end
