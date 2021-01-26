# frozen_string_literal: true

module CrmpClient
  # This is the primary class provided by the CrmpClient gem, providing a wrapper to call various Crmp API endpoints.
  #
  # This class provides methods which automatically deal with low-level concerns like paging of the Crmp API.
  class Client
    def initialize(base_uri, api_token)
      raise(ArgumentError, 'No base_uri - pass as param or set a default in initializer') unless base_uri
      raise(ArgumentError, 'No api_token - pass as param or set a default in initializer') unless api_token

      @api = CrmpClient::Api.new(base_uri, api_token)
    end

    # Non-paged APIs
    #
    # These take a unique identifier as a parameter, and return a hash containing the various fields for that object.

    # Get a single Membership object, looking it up using it's unique identifier
    def membership(identifier)
      @api.raw_api_call('membership.json', { identifier: identifier })
    end

    # Paged APIs
    #
    # These take variable arguments depending upon the API endpoint, but there are some common features.
    #
    # All methods accept an options hash, which allows the calling code to specify a starting page and maximum pages.
    # To set the starting page, set the `:page` option - this is 0-based and defaults to 0.
    # To set a maximum number of pages to return from the API, set the `:max_pages` option. By default this is `nil`
    # which means all pages are returned (aside from any pages skipped by the `:page` option).
    #
    # Each CRMP API endpoing has 2 corresponding methods, for example `lists` & `each_list`.
    # - `lists` returns all matching lists as one array of hash objects. This is useful if you need all objects in
    #   memory at the same time - but note, some of these objects are large & complex, and this could consume a lot of
    #   memory.
    # - `each_list` expects a block, and executes the block once for each list object returned by the API. This is
    #   recommended if you just want to perform an action with each object as it won't keep all objects in memory.
    #
    # For example, you could print out the name of each list using either `lists` or `each_list`, however `each_list`
    # would generally be preferred for memory efficiency:
    # - `crmp_client.lists.each { |list| puts "#{list.name}" }`
    # - `crmp_client.each_list { |list| puts "#{list.name}" }`

    # Get all all lists
    def lists(options = {})
      @api.collect_api_call('lists.json', {}, options).sort_by { |list| list['created_at'] }
    end

    # Iterate over each list
    def each_list(options = {}, &block)
      @api.each_api_call('lists.json', {}, options, block)
    end

    # Get all items which are in a specific list
    def list_items(list_id, options = {})
      @api.collect_api_call('list/items.json', { list_id: list_id }, options)
    end

    # Iterate over all items in a specific list
    def each_list_item(list_id, options = {}, &block)
      @api.each_api_call('list/items.json', { list_id: list_id }, options, block)
    end

    # Get all areas of a specific AreaClassification
    def areas(area_class, options = {})
      @api.collect_api_call('areas.json', { area_classification: area_class }, options)
    end

    # Iterate over all areas of a specific AreaClassification
    def each_area(area_class, options = {}, &block)
      @api.each_api_call('areas.json', { area_classification: area_class }, options, block)
    end

    # Get all areas of a specific AreaClassification, including memberships which represent each area
    def areas_with_memberships(area_class, options = {})
      @api.collect_api_call('areas/memberships.json', { area_classification: area_class }, options)
    end

    # Iterate over all areas of a specific AreaClassification, including memberships which represent each area
    def each_area_with_memberships(area_class, options = {}, &block)
      @api.each_api_call('areas/memberships.json', { area_classification: area_class }, options, block)
    end

    # Get all areas whose AreaClassification matches `contained_area_class`, and which are contained within the given
    # `containing_area_identifier`. Each area returned will also include a list of all areas which contain it.
    def area_containments(containing_area_identifier, contained_area_class, options = {})
      @api.collect_api_call(
        'areas/containments.json',
        { containing_area: containing_area_identifier, contained_area_classification: contained_area_class },
        options
      )
    end

    # Iterate over all areas whose AreaClassification matches `contained_area_class`, and which are contained within the
    # given `containing_area_identifier`. Each area returned will also include a list of all areas which contain it.
    def each_area_containment(containing_area_identifier, contained_area_class, options = {}, &block)
      @api.each_api_call(
        'areas/containments.json',
        { containing_area: containing_area_identifier, contained_area_classification: contained_area_class },
        options,
        block
      )
    end
  end
end
