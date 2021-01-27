# frozen_string_literal: true

require 'faraday'
require 'json'

module CrmpClient
  # Low-level class for calling the CRMP API. It is not recommended to use this class directly.
  # The +CrmpClient::Client+ class is designed to be directly used by applications.
  #
  # This class provides low-level wrappers for making HTTP calls to the CRMP application.
  class Api
    API_VERSION = 'v1'

    def initialize(crmp_base_uri, crmp_api_token)
      @httpclient = Faraday.new(
        url: "#{crmp_base_uri.chomp('/')}/api/#{API_VERSION}",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Authorization' => "Token token=#{crmp_api_token}"
        }
      )
    end

    # Helper method used to execute a block on each object returned by an API - particularly useful for paged API
    # endpoints, as this method handles iterating through all pages.
    #
    # This method only keeps a single page of results in-memory at a time.
    def each_api_call(path, params, options, block)
      paged_api_call(path, params, options) do |single_page_response|
        single_page_response['results'].each { |object| block.call(object) }
      end
    end

    # Helper method used to collect all API results into a single array - particularly useful for paged API endpoints
    # as this method handles iterating through all pages.
    #
    # Note that this may result in a large array which consumes a lot of memory.
    def collect_api_call(path, params, options)
      all_results = []
      paged_api_call(path, params, options) do |single_page_response|
        all_results << single_page_response['results']
      end
      all_results.flatten
    end

    # Helper method used by each_api_call & collect_api_call
    #
    # Calls the given `path` with the given `params`, starting with the page number specified in the options hash, and
    # fetching the maximum number of pages specified in the options hash. Expects a block to be given, which is passed
    # the response object for each page.
    #
    # By default, if no options are provided, this method fetches all pages.
    #
    # Although this includes logic for paging, if an endpoint is not paged, CRMP will ignore the `page` param, and
    # `response['next_page']` will be `nil`, so this logic will work on un-paged endpoints too.
    def paged_api_call(path, params, options, &block)
      page = options[:page] || 0
      max_pages = options[:max_pages]
      pages_processed = 0

      while page && (max_pages.nil? || pages_processed < max_pages)
        response = raw_api_call(path, params.merge({ page: page }))
        block.call(response) # execute the block passed by the calling method
        pages_processed += 1
        page = response['next_page'] # will be nil if there are no more pages, or if the API endpoint is un-paged
      end
    end

    # Helper method to make a raw API call. Returns the response body, parsed from JSON into a Ruby hash. If the
    # response status is not 200 (OK) it will raise an error.
    def raw_api_call(path, params)
      response = @httpclient.post(path, params.to_json)
      if response.status == 200
        parse_response(response)
      else
        CrmpClient.configuration.logger.error do
          "CRMP API Call to #{path} with #{params} failed with status #{response.status}"
        end
        raise CrmpClient::HttpError.new(response.status, response.body)
      end
    end

    def parse_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise(CrmpClient::InvalidResponseBodyError, e.message)
    end
  end
end
