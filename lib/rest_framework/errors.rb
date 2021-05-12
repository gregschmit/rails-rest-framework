# Top-level class for all REST Framework errors.
class RESTFramework::Error < StandardError
end


class RESTFramework::NilPassedToAPIResponseError < RESTFramework::Error
  def message
    return <<~MSG.split("\n").join(' ')
      Payload of `nil` was passed to `api_response`; this is unsupported. If you want a blank
      response, pass `''` (an empty string) as the payload. If this was the result of a `find_by`
      (or similar Active Record method) not finding a record, you should use the bang version (e.g.,
      `find_by!`) to raise `ActiveRecord::RecordNotFound`, which the REST controller will catch and
      return an appropriate error response.
    MSG
  end
end
