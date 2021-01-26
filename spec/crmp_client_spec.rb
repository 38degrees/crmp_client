# frozen_string_literal: true

RSpec.describe CrmpClient do
  it 'has a version number' do
    expect(CrmpClient::VERSION).not_to be nil
  end

  context '.new' do
    let(:default_base_uri) { 'https://crmp.default.org' }
    let(:default_api_token) { 'strong_token' }

    let(:override_base_uri) { 'https://crmp.non-standard.org' }
    let(:override_api_token) { 'another_strong_token' }

    context 'when CrmpClient has not been configured' do
      context 'when params are not provided' do
        it 'attempts to constructs a Client with nil arguments' do
          expect(CrmpClient::Client).to receive(:new).with(nil, nil)
          CrmpClient.new
        end
      end

      context 'when params are provided' do
        it 'constructs a Client with the provided params' do
          expect(CrmpClient::Client).to receive(:new).with(override_base_uri, override_api_token)
          CrmpClient.new(override_base_uri, override_api_token)
        end
      end
    end

    context 'when CrmpClient has been configured' do
      before do
        CrmpClient.configure do |config|
          config.default_base_uri = default_base_uri
          config.default_api_token = default_api_token
        end
      end

      context 'when params are not provided' do
        it 'constructs a Client with default arguments' do
          expect(CrmpClient::Client).to receive(:new).with(default_base_uri, default_api_token)
          CrmpClient.new
        end
      end

      context 'when params are provided' do
        it 'constructs a Client with the provided params' do
          expect(CrmpClient::Client).to receive(:new).with(override_base_uri, override_api_token)
          CrmpClient.new(override_base_uri, override_api_token)
        end
      end
    end
  end
end
