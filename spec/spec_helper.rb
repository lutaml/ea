# frozen_string_literal: true

require "bundler/setup"
require "fileutils"
require "lutaml/uml"
require "lutaml/uml_repository"
require "ea"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def fixtures_path(path)
  File.join(File.expand_path("./fixtures", __dir__), path)
end

$LOAD_PATH.unshift(File.expand_path("./support", __dir__))

# Load support files
Dir[File.expand_path("./support/**/*.rb", __dir__)].sort.each { |f| require f }
