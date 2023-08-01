# frozen_string_literal: true

require_relative 'lib/crmp_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'crmp_client'
  spec.version       = CrmpClient::VERSION
  spec.authors       = ['Andrew Sibley']
  spec.email         = ['andrew.s@38degrees.org.uk']

  spec.summary       = 'Ruby client for the 38 Degrees CRMP system.'
  spec.homepage      = 'https://github.com/38degrees/crmp_client'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
  # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'codecov', '>= 0.4'
  spec.add_development_dependency 'faker', '~> 2.15'
  spec.add_development_dependency 'pry', '>= 0.13'
  spec.add_development_dependency 'rake', '>= 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop', '~> 1.8'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.1'
  spec.add_development_dependency 'webmock', '~> 3.11'
  spec.add_development_dependency 'yard', '>= 0.9.26'
end
