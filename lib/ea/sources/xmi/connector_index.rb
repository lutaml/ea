# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Indexes the extension's `<connector>` nodes by `xmi:idref`. EA never
      # repeats `<source>`, `<target>`, `<properties>` or `<xrefs>` inside one
      # connector; if a hand-edited file does, the parse yields an Array where
      # a single node is read, so the first occurrence is kept.
      module ConnectorIndex
        SINGLE_NODES = %i[source target properties xrefs].freeze

        def self.build(root)
          connectors = root.extension&.connectors&.connector || []
          connectors.each_with_object({}) do |connector, index|
            next unless connector.idref

            SINGLE_NODES.each { |name| keep_first(connector, name) }
            index[connector.idref] = connector
          end
        end

        def self.keep_first(connector, name)
          value = connector.public_send(name)
          connector.public_send(:"#{name}=", value.first) if value.is_a?(Array)
        end
      end
    end
  end
end
