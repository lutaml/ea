# frozen_string_literal: true

require "fileutils"

module Ea
  module Spa
    module Output
      # Sharded layout: directory with skeleton.json, search.json,
      # and one JSON file per entity under data/. The frontend
      # loads skeleton + search upfront and fetches shards on
      # demand. This is the layout for large models.
      class ShardedMultiFileStrategy < Strategy
        def render(projector)
          FileUtils.mkdir_p(output_path)
          FileUtils.mkdir_p(File.join(output_path, "data"))

          skeleton = projector.skeleton
          write_json(File.join(output_path, "skeleton.json"), skeleton)
          write_json(File.join(output_path, "search.json"),
                     projector.search_index)
          write_shards(projector)
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
            </head>
            <body>
              <div id="app"></div>
              <script>
              window.__SPA_SKELETON_URL__ = 'skeleton.json';
              window.__SPA_SEARCH_URL__ = 'search.json';
              window.__SPA_SHARD_BASE__ = 'data/';
              </script>
            </body>
            </html>
          HTML
        end
      end
    end
  end
end
