# frozen_string_literal: true

require "fileutils"
require "json"

module Ea
  module Spa
    module Output
      # Embeds skeleton + search + every shard AND the pre-built SPA
      # bundle (JS + CSS) in one HTML file. Suitable for small models
      # only; not appropriate when shard count or total payload is
      # large.
      class SingleFileStrategy < Strategy
        def render(projector)
          assert_frontend_bundle!
          FileUtils.mkdir_p(File.dirname(output_path))

          skeleton = projector.skeleton
          payload = {
            metadata: skeleton.metadata,
            packageTree: skeleton.package_tree,
            skeletonEntries: skeleton.entries,
            searchIndex: projector.search_index,
            shards: projector.each_shard.to_a
          }
          payload[:viewExtras] = skeleton.view_extras unless skeleton.view_extras.nil? || skeleton.view_extras.empty?

          File.write(output_path, build_html(payload))
          output_path
        end

        private

        def build_html(payload)
          title = payload.dig(:viewExtras, "ui", "title") ||
                  payload[:metadata]&.fetch("title", nil) ||
                  "Ea::Spa"
          css = frontend_style_css || ""
          js  = frontend_app_js || ""
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>#{title}</title>
              <style>#{css}</style>
            </head>
            <body>
              <div id="app"></div>
              <script>
              window.__SPA_DATA__ = #{payload.to_json};
              </script>
              <script>#{js}</script>
            </body>
            </html>
          HTML
        end
      end
    end
  end
end
