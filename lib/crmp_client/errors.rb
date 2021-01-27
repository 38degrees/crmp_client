# frozen_string_literal: true

module CrmpClient
  # Base class for all CrmpClient errors
  class CrmpClientError < StandardError; end

  # Class to wrap errors caused by unexpected HTTP status codes
  class HttpError < CrmpClientError
    attr_reader :code, :body

    def initialize(code, body)
      super()
      @code = code
      @body = body
    end

    def message
      "HTTP code [#{@code}], response cody [#{@body}]"
    end
  end

  # Error to indicate that the HTTP body in the API response was invalid and could not be processed
  class InvalidResponseBodyError < CrmpClientError; end
end
