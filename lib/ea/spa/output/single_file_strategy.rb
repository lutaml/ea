# frozen_string_literal: true

require "fileutils"

module Ea
  module Spa
    module Output
      # Embeds skeleton + search + every shard in one HTML file
      # (data inlined as a JSON blob). Suitable for small models
      # only; not appropriate when shard count or total payload is
      # large.
      class SingleFileStrategy < Strategy
        def render(projector)
          FileUtils.mkdir_p(File.dirname(output_path))

          payload = {
            metadata: projector.skeleton.metadata,
            packageTree: projector.skeleton.package_tree,
            skeletonEntries: projector.skeleton.entries,
            searchIndex: projector.search_index,
            shards: projector.each_shard.to_a
          }

          File.write(output_path, build_html(payload))
          output_path
        end

        private

        def build_html(payload)
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>#{payload[:metadata]&.fetch("title", nil) || "Ea::Spa"}</title>
            </head>
            <body>
              <div id="app"></div>
              <script>
              window.__SPA_DATA__ = #{payload.to_json};
              </script>
            </body>
            </html>
          HTML
        end
      end
    end
  end
end
