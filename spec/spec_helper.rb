# frozen_string_literal: true

require 'timecop'
require 'vcr'
require 'webmock/rspec'

require_relative '../database'

VCR.configure do |config|
  config.cassette_library_dir = File.join(__dir__, 'cassettes')
  config.hook_into :webmock
  config.default_cassette_options = { record: :once }
  config.configure_rspec_metadata!
end

RSpec::Matchers.define_negated_matcher :not_be_empty, :be_empty

RSpec.configure do |config|
  config.define_derived_metadata { |meta| meta[:aggregate_failures] = true }
  config.before { Database.setup!(db_path: '') }
end
