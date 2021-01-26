# frozen_string_literal: true

require 'logger'

module CrmpClient
  # This class acts as a store for global configuration of the CrmpClient gem.
  #
  # A singleton instance of this class is created in the top-level +CrmpClient+ module code.
  class Configuration
    attr_accessor :default_base_uri, :default_api_token, :logger

    def initialize
      @default_base_uri = nil
      @default_api_token = nil

      @logger = defined?(Rails.logger) ? Rails.logger : Logger.new($stdout)
    end
  end
end
