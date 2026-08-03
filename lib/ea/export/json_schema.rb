# frozen_string_literal: true

require "json"

module Ea
  module Export
    # JSON Schema (draft 2020-12) export namespace.
    module JsonSchema
      autoload :Generator, "ea/export/json_schema/generator"
    end
  end
end
