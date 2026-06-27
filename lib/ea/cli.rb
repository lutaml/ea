# frozen_string_literal: true

module Ea
  module Cli
    autoload :App, "ea/cli/app"
    autoload :Command, "ea/cli/command"
    autoload :Output, "ea/cli/output"

    # All error classes live in ea/cli/error.rb — declare each so any
    # reference (not just Ea::Cli::Error) triggers the autoload.
    autoload :Error, "ea/cli/error"
    autoload :FileNotFound, "ea/cli/error"
    autoload :UnsupportedFormat, "ea/cli/error"
    autoload :MissingUmlDependency, "ea/cli/error"
    autoload :UnknownAction, "ea/cli/error"
  end
end
