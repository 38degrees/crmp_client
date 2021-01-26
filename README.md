# CrmpClient

CrmpClient is a Ruby Gem client for easy use of the API exposted by the Crmp application.

You must have access to a running instance of the Crmp application for this client to be of any use.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'crmp_client'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install crmp_client

## Usage

### Basic Example

```ruby
# Create the client
client = CrmpClient.new('https://crmp.my-organisation.org', 'my-api-token')

# Get all lists in the crmp instance
client.lists

# Iterate through each item in list 1
client.each_list_item(1)
```

### Configuring the client

Rather than passing the base URI and API token directly to `CrmpClient.new`, you can instead configure a default base URI, and default API token.

You can also override the default logger if desired. In a Rails environment this will automatically default to `Rails.logger`, and in non-rails will default to an instance of `Logger` logging to STDOUT.

For Rails apps, the recommendation is to configure the Crmp Client within an initializer file:

```ruby
# config/initializers/crmp_client.rb

CrmpClient.configure do |config|
  config.default_base_uri = 'https://crmp.my-organisation.org'
  config.default_api_token = 'my-api-token'

  # Override default logger if desired - defaults to `Rails.logger` for Rails apps / `Logger.new($stdout)` for non-Rails
  # config.logger = Rails.logger
end
```

If a default Base URI & API token have been configured, then a client can be created without any arguments:

```ruby
client = CrmpClient.new
```

However, you may still explicitly pass parameters to override the defaults:

```ruby
client = CrmpClient.new('https://crmp-staging.my-organisation.org', 'my-staging-api-token')
```

### Advanced options

Many of the APIs exposed by this gem return multiple objects - eg. all items in a list, or all areas matching some criteria.

This client exposes standard ways of getting all objects. For example, `client.lists` would get all lists, while `client.each_list { |list| ... }` would iterate over all lists, performing the given block on each list.

Sometimes a client may wish to start at a specific offset, of process only a limited number of pages of results - this can be achieved by providing any of the paged API calls with an options hash including the `:page` and/or `:max_pages` options, eg:

```ruby
client.lists({ page: 1, max_pages: 1})
```

The above example would start on page 1 (the default is page 0), and return only 1 page of results (by default it will return all pages).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/38degrees/crmp_client.
