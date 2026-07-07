# frozen_string_literal: true

require "bundler/setup"
require "fileutils"

# Load the optional UML bridge gems. Both `lutaml/uml` and
# `lutaml/uml_repository` are unreleased in their required forms
# (TODO.next/20): the published lutaml-uml 0.2.x doesn't ship
# `uml_repository`, and recent class additions (Generalization, etc.)
# may not be on the published 0.2.x line either. Local sibling-path
# development provides them; CI's rubygems pull may not.
#
# Each spec file that needs the bridge guards its examples on
# `defined?(::Lutaml::Uml)` / `defined?(::Lutaml::UmlRepository)`.
begin
  require "lutaml/uml"
rescue LoadError
  # Bridge specs skip at runtime.
end

require "ea"

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
