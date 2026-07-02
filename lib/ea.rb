# frozen_string_literal: true

# Load VERSION constant (defined in ea/version.rb per gemspec/gem-release
# convention). Use require_relative to avoid load-path dependencies during
# gemspec evaluation.
require_relative "ea/version"

module Ea
  class Error < StandardError; end

  autoload :Qea, "ea/qea"
  autoload :Diagram, "ea/diagram"
  autoload :Transformations, "ea/transformations"
  autoload :Xmi, "ea/xmi"
  autoload :Transformers, "ea/transformers"
  autoload :Cli, "ea/cli"
end
