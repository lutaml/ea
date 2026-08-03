# frozen_string_literal: true

module Ea
  module Export
    # XMI export namespace. Generates Sparx-flavored XMI from a
    # parsed model.
    module Xmi
      autoload :Generator, "ea/export/xmi/generator"
    end
  end
end
