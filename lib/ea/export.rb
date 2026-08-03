# frozen_string_literal: true

module Ea
  # Export namespace — format-specific exporters (XSD, PlantUML, etc.).
  # One sub-namespace per output format; each is independent and
  # autoloadable.
  module Export
    autoload :Json, "ea/export/json"
    autoload :JsonSchema, "ea/export/json_schema"
    autoload :PlantUml, "ea/export/plantuml"
    autoload :Xsd, "ea/export/xsd"
  end
end
