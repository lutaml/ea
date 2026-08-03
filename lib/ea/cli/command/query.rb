# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea query FILE [--type=T] [--package=NAME] [--stereo=NAME]`
      #
      # Wraps Ea::Query::Builder for CLI consumption.
      class Query < Base
        COLUMNS = %i[id type name package].freeze

        def call
          builder = Ea::Query::Builder.new(model)
          builder = builder.with_type(options[:type]) if options[:type]
          builder = builder.in_package(options[:package]) if options[:package]
          builder = builder.with_stereotype(options[:stereotype]) if options[:stereotype]
          rows = builder.call.map { |o| [o.object_id, o.object_type, o.name, package_name_for(o)] }
          formatter.render(rows, columns: COLUMNS)
        end

        private

        def model
          @model ||= load_database(file_path)
        end

        def package_name_for(obj)
          pkg = (model.collections[:packages] || []).find { |p| p.package_id == obj.package_id }
          pkg&.name || "-"
        end
      end
    end
  end
end
