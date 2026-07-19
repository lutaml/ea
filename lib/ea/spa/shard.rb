# frozen_string_literal: true

module Ea
  module Spa
    # Per-entity detail payload. Plain Ruby value object (not a
    # lutaml-model type) because the payload is an arbitrary JSON
    # blob whose shape depends on the model element's kind — we
    # don't want the framework's hash-type cast getting in the way.
    Shard = Struct.new(:id, :kind, :payload, keyword_init: true) do
      def to_h
        { "id" => id, "kind" => kind, "payload" => payload }
      end

      def to_json(*args)
        JSON.generate(to_h, *args)
      end
    end
  end
end
