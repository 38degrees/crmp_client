# frozen_string_literal: true

RSpec.describe CrmpClient::Client do
  subject { described_class.new(base_uri, api_token) }

  let(:base_uri) { 'https://crmp.dummy-uri.org' }
  let(:api_token) { 'dummy_api_token' }

  ###########################
  ##### SHARED EXAMPLES #####
  ###########################

  RSpec.shared_examples 'an API which raises errors' do
    context 'when the request returns 200 (success) but an invalid JSON response' do
      it 'raises an InvalidResponseBodyError' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params,
          response_status: 200,
          response_body: invalid_json
        )

        expect do
          subject.send(method, *method_params)
        end.to raise_error(CrmpClient::InvalidResponseBodyError)

        expect(request).to have_been_requested.once
      end
    end

    context 'when the request returns non-200 (failure)' do
      it 'raises an HttpError with the appropriate HTTP code' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params,
          response_status: 500,
          response_body: dummy_single_object.to_json
        )

        expect do
          subject.send(method, *method_params)
        end.to raise_error(CrmpClient::HttpError, /HTTP code \[500\]/)

        expect(request).to have_been_requested.once
      end
    end
  end

  # Shared tests for APIs which don't have any paging - they simply return a single JSON object.
  # Requires some context variables to be setup & in scope to run:
  # - subject - the Client instance being tested
  # - method - the name of the method we're testing
  # - method_params - the input parameters we're testing with
  # - request_path - the path the client is expected to make an HTTP call against
  # - request_params - the parameters the client is expected to send in the body of the POST HTTP call
  RSpec.shared_examples 'a non-paged API' do
    context 'when the request returns 200 (success) and a valid JSON response' do
      it 'returns the response body, parsed into a hash' do
        result_data = dummy_single_object

        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params,
          response_status: 200,
          response_body: result_data.to_json
        )

        expect(subject.send(method, *method_params)).to eq(result_data)

        expect(request).to have_been_requested.once
      end
    end

    it_behaves_like 'an API which raises errors'
  end

  # Shared tests for APIs which have paging, and collect all data from all pages into a collection for consumption.
  # Requires some context variables to be setup & in scope to run:
  # - subject - the Client instance being tested
  # - method - the name of the method we're testing
  # - method_params - an array of the input parameters we're testing the method with
  # - request_path - the path the client is expected to make an HTTP call against
  # - request_params - the parameters the client is expected to send in the body of the POST HTTP call
  RSpec.shared_examples 'a paged collection API' do
    let(:result_data_page0) { dummy_array_object }
    let(:result_data_page1) { dummy_array_object }

    context 'when the request returns 200 (success) and indicates no more pages' do
      it 'returns a collection containing all data' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 0 }),
          response_status: 200,
          response_body: { 'results' => result_data_page0, 'next_page' => nil }.to_json
        )

        expect(subject.send(method, *method_params)).to eq(result_data_page0)

        expect(request).to have_been_requested.once
      end
    end

    context 'when the request returns 200 (success) and indicates more pages' do
      it 'makes further HTTP calls, and returns a collection containing all data' do
        all_result_data = result_data_page0 + result_data_page1

        request1 = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 0 }),
          response_status: 200,
          response_body: { 'results' => result_data_page0, 'next_page' => 1 }.to_json
        )

        request2 = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 1 }),
          response_status: 200,
          response_body: { 'results' => result_data_page1, 'next_page' => nil }.to_json
        )

        expect(subject.send(method, *method_params)).to eq(all_result_data)

        expect(request1).to have_been_requested.once
        expect(request2).to have_been_requested.once
      end
    end

    context 'when the pages option is set' do
      let(:method_params) { super() << { page: 1 } } # Add the options hash to our method params

      it 'passes the pages parameter through to the HTTP API call' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 1 }),
          response_status: 200,
          response_body: { 'results' => result_data_page1, 'next_page' => nil }.to_json
        )

        expect(subject.send(method, *method_params)).to eq(result_data_page1)

        expect(request).to have_been_requested.once
      end
    end

    context 'when the max_pages option is set' do
      let(:method_params) { super() << { max_pages: 1 } } # Add the options hash to our method params

      it 'only calls the HTTP API the appropriate number of times, even if there are more pages' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 0 }),
          response_status: 200,
          response_body: { 'results' => result_data_page0, 'next_page' => 1 }.to_json
        )

        expect(subject.send(method, *method_params)).to eq(result_data_page0)

        expect(request).to have_been_requested.once
      end
    end

    it_behaves_like 'an API which raises errors' do
      # Override old value of request_params, paged APIs always include the page param
      let(:request_params) { super().merge({ page: 0 }) }
    end
  end

  # Shared tests for APIs which have paging, and iterate over each result from all pages in turn.
  RSpec.shared_examples 'a paged iterating API' do
    let(:result_data_page0) { dummy_array_object }
    let(:result_data_page1) { dummy_array_object }

    context 'when the request returns 200 (success) and indicates no more pages' do
      it 'iterates over the correct elements' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 0 }),
          response_status: 200,
          response_body: { 'results' => result_data_page0, 'next_page' => nil }.to_json
        )

        # Collect the identifiers, so we can check all items were indeed iterated over by the client method call
        identifiers = []
        subject.send(method, *method_params) { |item| identifiers << item['identifier'] }
        expect(identifiers).to eq(result_data_page0.map { |i| i['identifier'] })

        expect(request).to have_been_requested.once
      end
    end

    context 'when the request returns 200 (success) and indicates more pages' do
      it 'makes further HTTP calls, and returns a collection containing all data' do
        all_result_data = result_data_page0 + result_data_page1

        request1 = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 0 }),
          response_status: 200,
          response_body: { 'results' => result_data_page0, 'next_page' => 1 }.to_json
        )

        request2 = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 1 }),
          response_status: 200,
          response_body: { 'results' => result_data_page1, 'next_page' => nil }.to_json
        )

        # Collect the identifiers, so we can check all items were indeed iterated over by the client method call
        identifiers = []
        subject.send(method, *method_params) { |item| identifiers << item['identifier'] }
        expect(identifiers).to eq(all_result_data.map { |i| i['identifier'] })

        expect(request1).to have_been_requested.once
        expect(request2).to have_been_requested.once
      end
    end

    context 'when the pages option is set' do
      let(:method_params) { super() << { page: 1 } } # Add the options hash to our method params

      it 'passes the pages parameter through to the HTTP API call' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 1 }),
          response_status: 200,
          response_body: { 'results' => result_data_page1, 'next_page' => nil }.to_json
        )

        # Collect the identifiers, so we can check all items were indeed iterated over by the client method call
        identifiers = []
        subject.send(method, *method_params) { |item| identifiers << item['identifier'] }
        expect(identifiers).to eq(result_data_page1.map { |i| i['identifier'] })

        expect(request).to have_been_requested.once
      end
    end

    context 'when the max_pages option is set' do
      let(:method_params) { super() << { max_pages: 1 } } # Add the options hash to our method params

      it 'only calls the HTTP API the appropriate number of times, even if there are more pages' do
        request = stub_crmp_request(
          request_path: request_path,
          request_params: request_params.merge({ page: 0 }),
          response_status: 200,
          response_body: { 'results' => result_data_page0, 'next_page' => 1 }.to_json
        )

        # Collect the identifiers, so we can check all items were indeed iterated over by the client method call
        identifiers = []
        subject.send(method, *method_params) { |item| identifiers << item['identifier'] }
        expect(identifiers).to eq(result_data_page0.map { |i| i['identifier'] })

        expect(request).to have_been_requested.once
      end
    end

    it_behaves_like 'an API which raises errors' do
      # Override old value of request_params, paged APIs always include the page param
      let(:request_params) { super().merge({ page: 0 }) }
    end
  end

  #######################
  ##### TESTS BEGIN #####
  #######################

  # Non-paged APIs
  describe '#membership' do
    it_behaves_like 'a non-paged API' do
      let(:method) { :membership }
      let(:method_params) { ['1234'] }

      let(:request_path) { 'membership.json' }
      let(:request_params) { { identifier: '1234' } }
    end
  end

  # Paged APIs
  describe '#lists' do
    it_behaves_like 'a paged collection API' do
      let(:method) { :lists }
      let(:method_params) { [] }

      let(:request_path) { 'lists.json' }
      let(:request_params) { {} }
    end
  end

  describe '#each_list' do
    it_behaves_like 'a paged iterating API' do
      let(:method) { :each_list }
      let(:method_params) { [] }

      let(:request_path) { 'lists.json' }
      let(:request_params) { {} }
    end
  end

  describe '#list_items' do
    it_behaves_like 'a paged collection API' do
      let(:method) { :list_items }
      let(:method_params) { [123] }

      let(:request_path) { 'list/items.json' }
      let(:request_params) { { list_id: 123 } }
    end
  end

  describe '#each_list_item' do
    it_behaves_like 'a paged iterating API' do
      let(:method) { :each_list_item }
      let(:method_params) { [123] }

      let(:request_path) { 'list/items.json' }
      let(:request_params) { { list_id: 123 } }
    end
  end

  describe '#areas' do
    it_behaves_like 'a paged collection API' do
      let(:method) { :areas }
      let(:method_params) { ['Postcode'] }

      let(:request_path) { 'areas.json' }
      let(:request_params) { { area_classification: 'Postcode' } }
    end
  end

  describe '#each_area' do
    it_behaves_like 'a paged iterating API' do
      let(:method) { :each_area }
      let(:method_params) { ['Postcode'] }

      let(:request_path) { 'areas.json' }
      let(:request_params) { { area_classification: 'Postcode' } }
    end
  end

  describe '#areas_with_memberships' do
    it_behaves_like 'a paged collection API' do
      let(:method) { :areas_with_memberships }
      let(:method_params) { ['Constituency'] }

      let(:request_path) { 'areas/memberships.json' }
      let(:request_params) { { area_classification: 'Constituency' } }
    end
  end

  describe '#each_area_with_memberships' do
    it_behaves_like 'a paged iterating API' do
      let(:method) { :each_area_with_memberships }
      let(:method_params) { ['Constituency'] }

      let(:request_path) { 'areas/memberships.json' }
      let(:request_params) { { area_classification: 'Constituency' } }
    end
  end

  describe '#area_containments' do
    it_behaves_like 'a paged collection API' do
      let(:method) { :area_containments }
      let(:method_params) { %w[Westminster Postcode] }

      let(:request_path) { 'areas/containments.json' }
      let(:request_params) { { containing_area: 'Westminster', contained_area_classification: 'Postcode' } }
    end
  end

  describe '#each_area_containment' do
    it_behaves_like 'a paged iterating API' do
      let(:method) { :each_area_containment }
      let(:method_params) { %w[Westminster Postcode] }

      let(:request_path) { 'areas/containments.json' }
      let(:request_params) { { containing_area: 'Westminster', contained_area_classification: 'Postcode' } }
    end
  end

  # Error-case testing against .new
  describe '.new' do
    context 'when base_uri not provided' do
      it 'raises an ArgumentError' do
        expect { described_class.new(nil, api_token) }.to raise_error(ArgumentError)
      end
    end

    context 'when api_token not provided' do
      it 'raises an ArgumentError' do
        expect { described_class.new(base_uri, nil) }.to raise_error(ArgumentError)
      end
    end
  end

  ##########################
  ##### HELPER METHODS #####
  ##########################

  # Stubs a Crmp API request.
  # Expects an API call to the given path (this method deals with adding the base URI and base API path), with the
  # given parameters, and also checks for the required headers (content, Auth, etc).
  # The stub API call will return the given response status and body.
  def stub_crmp_request(request_path:, request_params:, response_status:, response_body:)
    uri = "#{base_uri}/api/v1/#{request_path}"
    request_body = request_params.to_json

    stub_request(:post, uri)
      .with { |request| request.body == request_body && correct_headers?(request) }
      .to_return(status: response_status, body: response_body)
  end

  def correct_headers?(request)
    request.headers['Content-Type'] =~ %r{application/json} &&
      request.headers['Accept'] =~ %r{application/json} &&
      request.headers['Authorization'] == "Token token=#{api_token}"
  end

  def dummy_single_object
    { 'identifier' => Faker::Number.hexadecimal(digits: 10), 'name' => Faker::Name.name }
  end

  def dummy_array_object
    [
      dummy_single_object,
      dummy_single_object
    ]
  end

  def invalid_json
    '{Invalid_JSON]'
  end
end
