# frozen_string_literal: true

module Ea
  VERSION = "0.1.0"

  class Error < StandardError; end

  autoload :Qea, "ea/qea"
  autoload :Diagram, "ea/diagram"
  autoload :Transformations, "ea/transformations"
  autoload :Xmi, "ea/xmi"
  autoload :Transformers, "ea/transformers"
  autoload :Cli, "ea/cli"
end
