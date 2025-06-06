# frozen_string_literal: true

require "rspec"
require_relative "../lib/agtron"

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use documentation format
  config.formatter = :documentation

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option
  Kernel.srand config.seed

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run before each example
  config.before(:each) do
    # Add any setup needed before each test
  end
end
