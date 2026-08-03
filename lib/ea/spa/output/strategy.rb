# frozen_string_literal: true

require "fileutils"

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

        # Path to the pre-built Vue IIFE bundle shipped with the gem.
        # Built from frontend/ via `npm run build`; committed so the
        # gem never needs npm at install time. Resolved lazily so a
        # missing bundle raises a clear error pointing at frontend/.
        FRONTEND_DIST_DIR = File.expand_path("../../../../frontend/dist", __dir__)
        FRONTEND_APP_JS   = File.join(FRONTEND_DIST_DIR, "app.iife.js")
        FRONTEND_STYLE_CSS = File.join(FRONTEND_DIST_DIR, "style.css")

        attr_reader :output_path

        def initialize(output_path)
          @output_path = output_path
        end

        def render(_projector)
          raise NotImplementedError,
                "#{self.class} must implement #render"
        end

        protected

        # The pre-built SPA application source as a String, for
        # embedding directly into a single-file output. Returns nil
        # if the bundle has not been built (e.g. running from a
        # source checkout before `npm run build`).
        def frontend_app_js
          return nil unless File.exist?(FRONTEND_APP_JS)
          File.read(FRONTEND_APP_JS)
        end

        def frontend_style_css
          return nil unless File.exist?(FRONTEND_STYLE_CSS)
          File.read(FRONTEND_STYLE_CSS)
        end

        def assert_frontend_bundle!
          unless File.exist?(FRONTEND_APP_JS) && File.exist?(FRONTEND_STYLE_CSS)
            raise Ea::Error,
                  "SPA frontend bundle not found under #{FRONTEND_DIST_DIR}. " \
                  "Run `cd frontend && npm install && npm run build`."
          end
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
