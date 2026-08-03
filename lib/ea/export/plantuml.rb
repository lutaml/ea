# frozen_string_literal: true

module Ea
  module Export
    # PlantUML text-format exporter. Produces a `.puml` file
    # documenting the model's classes, attributes, and relationships
    # in PlantUML syntax (rendered by plantuml.com/plantuml).
    module PlantUml
      autoload :Generator, "ea/export/plantuml/generator"
    end
  end
end
