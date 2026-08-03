# frozen_string_literal: true

module Ea
  module Svg
    # Render-fidelity measurement. Compares emitted SVG against
    # EA-produced reference SVGs so parity can be scored on any
    # source format (.qea or .xmi) from specs or a rake task.
    module Parity
      autoload :Checker, "ea/svg/parity/checker"
      autoload :Suite, "ea/svg/parity/suite"
      autoload :Source, "ea/svg/parity/source"
    end
  end
end
