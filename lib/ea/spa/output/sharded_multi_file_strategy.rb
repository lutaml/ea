# frozen_string_literal: true

require "fileutils"

module Ea
  module Spa
    module Output
      # Sharded layout: directory with skeleton.json, search.json,
      # one JSON file per entity under data/, the pre-built SPA
      # bundle (app.js + style.css), and an index.html shell that
      # ties them together. The frontend loads skeleton + search
      # upfront and fetches shards on demand. Suitable for large
      # models that won't fit comfortably in a single HTML file.
      class ShardedMultiFileStrategy < Strategy
        def render(projector)
          assert_frontend_bundle!
          FileUtils.mkdir_p(output_path)
          FileUtils.mkdir_p(File.join(output_path, "data"))

          skeleton = projector.skeleton
          write_json(File.join(output_path, "skeleton.json"), skeleton)
          write_json(File.join(output_path, "search.json"),
                     projector.search_index)
          write_shards(projector)
          write_assets
          write_index_html(skeleton)

          output_path
        end

        private

        def write_shards(projector)
          projector.each_shard.each do |shard|
            path = File.join(output_path, "data", pluralize(shard.kind),
                             "#{shard.id}.json")
            write_json(path, shard)
          end
        end

        def pluralize(kind)
          case kind
          when "class" then "classes"
          when "property" then "properties"
          else "#{kind}s"
          end
        end

        # Copy the pre-built JS + CSS bundles next to index.html so
        # the shell can <script src="app.js"> them. Assets are always
        # the same bytes for every generation, so a plain file copy
        # is both simplest and fastest.
        def write_assets
          FileUtils.cp(FRONTEND_APP_JS,    File.join(output_path, "app.js"))
          FileUtils.cp(FRONTEND_STYLE_CSS, File.join(output_path, "style.css"))
        end

        def write_index_html(skeleton)
          title = skeleton.view_extras&.dig("ui", "title") ||
                  skeleton.metadata&.fetch("title", nil) ||
                  "Ea::Spa"
          File.write(File.join(output_path, "index.html"), <<~HTML)
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>#{title}</title>
              <link rel="stylesheet" href="style.css">
            </head>
            <body>
              <div id="app"></div>
              <script>
              window.__SPA_SKELETON_URL__ = 'skeleton.json';
              window.__SPA_SEARCH_URL__ = 'search.json';
              window.__SPA_SHARD_BASE__ = 'data/';
              </script>
              <script src="app.js" defer></script>
            </body>
            </html>
          HTML
        end
      end
    end
  end
end
