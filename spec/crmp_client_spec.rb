# frozen_string_literal: true

RSpec.describe CrmpClient do
  it 'has a version number' do
    expect(CrmpClient::VERSION).not_to be nil
  end

  describe '.new' do
    let(:default_base_uri) { 'https://crmp.default.org' }
    let(:default_api_token) { 'strong_token' }

    let(:override_base_uri) { 'https://crmp.non-standard.org' }
    let(:override_api_token) { 'another_strong_token' }

    before do
      allow(CrmpClient::Client).to receive(:new)
    end

    context 'when CrmpClient has not been configured' do
      context 'when params are not provided' do
        it 'attempts to constructs a Client with nil arguments' do
          described_class.new
          expect(CrmpClient::Client).to have_received(:new).with(nil, nil)
        end
      end

      context 'when params are provided' do
        it 'constructs a Client with the provided params' do
          described_class.new(override_base_uri, override_api_token)
          expect(CrmpClient::Client).to have_received(:new).with(override_base_uri, override_api_token)
        end
      end
    end

    context 'when CrmpClient has been configured' do
      before do
        described_class.configure do |config|
          config.default_base_uri = default_base_uri
          config.default_api_token = default_api_token
        end
      end

      context 'when params are not provided' do
        it 'constructs a Client with default arguments' do
          described_class.new
          expect(CrmpClient::Client).to have_received(:new).with(default_base_uri, default_api_token)
        end
      end

      context 'when params are provided' do
        it 'constructs a Client with the provided params' do
          described_class.new(override_base_uri, override_api_token)
          expect(CrmpClient::Client).to have_received(:new).with(override_base_uri, override_api_token)
        end
      end
    end
  end
end
