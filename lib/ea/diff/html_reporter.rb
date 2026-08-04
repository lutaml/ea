# frozen_string_literal: true

module Ea
  module Diff
    # Renders a Comparator's differences as an HTML report with
    # color-coded rows. Useful for CI artifacts and PR review.
    class HtmlReporter
      attr_reader :comparator

      def initialize(comparator)
        @comparator = comparator
      end

      # @return [String] standalone HTML document
      def render
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
            <title>EA Diff Report</title>
            <style>#{css}</style>
          </head>
          <body>
            <h1>EA Diff Report</h1>
            #{summary_section}
            #{table_section}
          </body>
          </html>
        HTML
      end

      private

      def summary_section
        added = comparator.differences.count(&:added?)
        removed = comparator.differences.count(&:removed?)
        renamed = comparator.differences.count(&:renamed?)
        <<~HTML
          <section class="summary">
            <span class="added">+#{added} added</span>
            <span class="removed">-#{removed} removed</span>
            <span class="renamed">~#{renamed} renamed</span>
          </section>
        HTML
      end

      def table_section
        rows = comparator.differences.map do |diff|
          %(<tr class="#{diff.change}"><td>#{escape(diff.change)}</td>" \
            "<td>#{escape(diff.kind)}</td><td>#{escape(diff.id)}</td>" \
            "<td>#{escape(diff.name)}</td></tr>")
        end.join("\n")
        <<~HTML
          <table>
            <thead><tr><th>Change</th><th>Kind</th><th>ID</th><th>Name</th></tr></thead>
            <tbody>
            #{rows}
            </tbody>
          </table>
        HTML
      end

      def css
        <<~CSS
          body { font-family: -apple-system, system-ui, sans-serif; margin: 2em; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid #ddd; padding: 0.5em; text-align: left; }
          tr.added { background: #e6ffe6; }
          tr.removed { background: #ffe6e6; }
          tr.renamed { background: #fff9e6; }
          .summary { margin: 1em 0; }
          .summary span { padding: 0.25em 0.5em; margin-right: 0.5em; border-radius: 3px; }
          .added { background: #d4edda; color: #155724; }
          .removed { background: #f8d7da; color: #721c24; }
          .renamed { background: #fff3cd; color: #856404; }
        CSS
      end

      def escape(text)
        return "" if text.nil?

        XmlEscape.call(text)
      end
    end
  end
end
