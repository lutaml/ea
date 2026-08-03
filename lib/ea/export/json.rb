# frozen_string_literal: true

module Ea
  module Export
    # JSON serialization namespace. Produces a JSON document of the
    # model's collections, suitable for downstream tools (web apps,
    # diff tools, etc.).
    module Json
      autoload :Generator, "ea/export/json/generator"
    end
  end
end
