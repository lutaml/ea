# frozen_string_literal: true

require "bundler/setup"
require "fileutils"
require "lutaml/uml"
require "ea"

# The UML bridge depends on `lutaml/uml_repository`, which is not yet
# released (no published version of lutaml-uml ships the file — see
# TODO.next/20). When the local path checkout provides it, load it;
# otherwise skip — the bridge specs guard on its presence via the
# `Lutaml::UmlRepository` constant.
begin
  require "lutaml/uml_repository"
rescue LoadError
  # Bridge specs that need uml_repository are skipped at runtime via
  # `before { skip "..." unless defined?(Lutaml::UmlRepository) }`.
end

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
