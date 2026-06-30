# frozen_string_literal: true

module Ea
  module Cli
    module Command
      autoload :Base, "ea/cli/command/base"
      autoload :List, "ea/cli/command/list"
      autoload :Diagrams, "ea/cli/command/diagrams"
      autoload :Validate, "ea/cli/command/validate"
      autoload :Stats, "ea/cli/command/stats"
      autoload :Parse, "ea/cli/command/parse"
      autoload :Convert, "ea/cli/command/convert"
    end
  end
end
