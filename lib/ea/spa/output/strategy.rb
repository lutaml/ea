# frozen_string_literal: true

module Ea
  module Spa
    module Output
      # Abstract output strategy. Concrete subclasses project the
      # same SPA artifacts (skeleton, search index, shards) to disk
      # in different layouts.
      #
      # Adding a new layout = new subclass + registration in
      # Generator::OUTPUT_STRATEGIES. No edit to Projector or
      # existing strategies.
      class Strategy
        SIZE_THRESHOLD_BYTES = 2 * 1024 * 1024 # 2 MB

        attr_reader :output_path

        def initialize(output_path)
          @output_path = output_path
        end

        def render(_projector)
          raise NotImplementedError,
                "#{self.class} must implement #render"
        end

        private

        def write_json(path, data)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, data.to_json)
        end
      end
    end
  end
end
