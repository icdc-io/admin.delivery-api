module ResponseHelper

  def success(body)
    c_response('200', body)
  end

  def no_content
    c_response('204')
  end

  def not_authorized
    c_response('401', {:message => "You're not authorized."})
  end

  def not_found(object)
    c_response('404', {:message => "Bad request, not found #{object}"})
  end

  def forbidden(body)
    c_response('403', body)
  end

  def abort(message)
    c_response('500', {:message => "Something went wrong. \n #{message}"})
  end

  private

  def c_response(code, body = nil)
    render :json => {
      :status => code.to_i,
      # TODO: leave this field for backward compatibility, remove it in future
      :data => body,
      # end TODO
      :message => body
    }, status: code
  end
end
