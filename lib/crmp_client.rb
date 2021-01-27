# frozen_string_literal: true

require_relative 'crmp_client/api'
require_relative 'crmp_client/errors'
require_relative 'crmp_client/client'
require_relative 'crmp_client/configuration'
require_relative 'crmp_client/version'

# The main namespace for CrmpClient.
#
# It provides methods to configure the gem, and a convenience method to create a new +Client+ object.
#
module CrmpClient
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Return a new Client (which provides all the functionality of this gem), using passed parameters or the
    # configured defaults.
    def new(crmp_base_uri = nil, crmp_api_token = nil)
      base_uri = crmp_base_uri || configuration.default_base_uri
      api_token = crmp_api_token || configuration.default_api_token

      Client.new(base_uri, api_token)
    end
  end
end
