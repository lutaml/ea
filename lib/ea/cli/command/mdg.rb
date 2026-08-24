# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea mdg ACTION [ARG]`
      #
      # Actions:
      #   list                 — list registered technologies
      #   show NAME            — show stereotype details
      #   stereotypes          — list all stereotypes across technologies
      class Mdg < Base
        COLUMNS = %i[name version stereotypes].freeze

        def call
          case action
          when "list" then list_technologies
          when "show" then show_stereotype(arg)
          when "stereotypes" then list_stereotypes
          else
            raise Ea::Cli::Error,
                  "Unknown mdg action: #{action}. " \
                  "Valid: list | show NAME | stereotypes"
          end
        end

        private

        def action
          options[:action]
        end

        def arg
          options[:arg]
        end

        def registry
          @registry ||= build_registry
        end

        def build_registry
          Ea::Mdg::Registry.from_paths(["spec/fixtures/mdg"])
        end

        def list_technologies
          rows = registry.documents.map do |doc|
            [doc.technology_name, "-", (doc.stereotypes || []).size]
          end
          formatter.render(rows, columns: COLUMNS)
        end

        def list_stereotypes
          rows = []
          registry.documents.each do |doc|
            (doc.stereotypes || []).each do |st|
              rows << [doc.technology_name, st.name, st.applies_to.join(",")]
            end
          end
          formatter.render(rows, columns: %i[technology name applies_to])
        end

        def show_stereotype(name)
          return unless name

          found = nil
          registry.documents.each do |doc|
            st = (doc.stereotypes || []).find { |s| s.name == name }
            next unless st

            found = { technology: doc.technology_name, stereo: st }
            break
          end

          if found
            formatter.render(
              [[found[:technology], found[:stereo].name,
                found[:stereo].applies_to.join(","),
                (found[:stereo].tagged_values || []).size]],
              columns: %i[technology name applies_to tagged_values]
            )
          else
            warn "Stereotype #{name.inspect} not found"
            exit(1)
          end
        end
      end
    end
  end
end
