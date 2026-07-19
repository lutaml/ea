# frozen_string_literal: true

module Ea
  module Spa
    # Orchestrator: takes an Ea::Model::Document and an output mode,
    # dispatches to the matching Output::Strategy. Single source of
    # truth for which modes exist; new modes = one entry in
    # OUTPUT_STRATEGIES.
    class Generator
      OUTPUT_STRATEGIES = {
        single_file: Output::SingleFileStrategy,
        sharded: Output::ShardedMultiFileStrategy
      }.freeze

      DEFAULT_MODE = :single_file

      attr_reader :document, :mode, :output_path, :shard_url_for

      def initialize(document, output:, mode: nil, shard_url_for: nil)
        @document = document
        @output_path = output
        @mode = (mode || DEFAULT_MODE).to_sym
        @shard_url_for = shard_url_for
      end

      def generate
        strategy_class.new(output_path).render(projector)
      end

      def projector
        @projector ||= Projector.new(document, shard_url_for: shard_url_for)
      end

      def strategy_class
        OUTPUT_STRATEGIES[mode] ||
          raise(ArgumentError, "Unknown SPA mode: #{mode.inspect}. " \
                                "Use :single_file or :sharded.")
      end
    end
  end
end
