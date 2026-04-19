module RESTFramework::Errors
  class BaseError < StandardError
  end

  class NilPassedToRenderAPIError < BaseError
    def message
      <<~MSG.split("\n").join(" ")
        Payload of `nil` was passed to `render_api`; this is unsupported. If you want a blank
        response, pass `''` (an empty string) as the payload. If this was the result of a `find_by`
        (or similar Active Record method) not finding a record, you should use the bang version
        (e.g., `find_by!`) to raise `ActiveRecord::RecordNotFound`, which the REST controller will
        catch and return an appropriate error response.
      MSG
    end
  end

  class InvalidBulkParametersError < BaseError
    def initialize(detail = nil)
      @detail = detail
    end

    def message
      msg = "Invalid request parameters for bulk action."
      msg += " #{@detail}" if @detail
      msg
    end
  end

  class BulkRecordErrorsError < BaseError
    attr_reader :errors

    def initialize(records)
      @errors = records.each_with_index.filter_map { |record, i|
        next unless record.errors.any?
        { index: i, errors: record.errors.messages }
      }
    end

    # Allow `e.try(:record).try(:errors)` to chain through the standard error handler.
    def record
      self
    end

    def message
      "Bulk operation failed due to validation errors on #{@errors.length} #{
        'record'.pluralize(@errors.length)
      }."
    end
  end
end

# Aliases for convenience.
RESTFramework::BaseError = RESTFramework::Errors::BaseError
RESTFramework::NilPassedToRenderAPIError = RESTFramework::Errors::NilPassedToRenderAPIError
RESTFramework::InvalidBulkParametersError = RESTFramework::Errors::InvalidBulkParametersError
RESTFramework::BulkRecordErrorsError = RESTFramework::Errors::BulkRecordErrorsError
