# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Sparx XMI namespace URIs and the profile-namespace registry.
      #
      # The fixed XMI/UML/UMLDI/DC namespaces are emitted on every document.
      # Profile namespaces (thecustomprofile, GML, StandardProfileL2, ...) are
      # emitted only when at least one stereotype from that profile is applied.
      module SparxNamespaces
        XMI   = "http://www.omg.org/spec/XMI/20131001"
        UML   = "http://www.omg.org/spec/UML/20161101"
        UMLDI = "http://www.omg.org/spec/UML/20161101/UMLDI"
        DC    = "http://www.omg.org/spec/UML/20161101/UMLDC"

        BASE = {
          "xmlns:xmi": XMI,
          "xmlns:uml": UML,
          "xmlns:umldi": UMLDI,
          "xmlns:dc": DC,
        }.freeze

        # @return [Hash] profile_key → [prefix, uri]. Lookup is case-insensitive
        #   on the profile name (Sparx normalizes to lowercase in xrefs).
        @profiles = {
          "thecustomprofile" =>
            ["thecustomprofile",
             "http://www.sparxsystems.com/profiles/thecustomprofile/1.0"],
          "gml" =>
            ["GML",
             "http://www.sparxsystems.com/profiles/GML/1.0"],
          "standardprofilel2" =>
            ["StandardProfileL2",
             "http://www.omg.org/spec/UML/20110701/StandardProfileL2.xmi"],
        }.freeze

        class << self
          # Register an additional profile namespace at load time (OCP).
          # @param profile_name [String] Sparx profile name (case-insensitive)
          # @param prefix [String] XML namespace prefix
          # @param uri [String] XML namespace URI
          # @return [void]
          def register_profile(profile_name, prefix:, uri:)
            @profiles = @profiles.merge(profile_name.downcase => [prefix, uri])
          end

          # @param profile_name [String, nil]
          # @return [Array(String, String), nil] [prefix, uri]
          def profile_for(profile_name)
            return nil if profile_name.nil?

            @profiles[profile_name.downcase]
          end

          # @param profile_names [Array<String>]
          # @return [Hash] namespace declarations for the given profiles
          def profile_namespaces_for(profile_names)
            profile_names.uniq.each_with_object({}) do |name, h|
              prefix, uri = profile_for(name)
              next unless prefix

              h[:"xmlns:#{prefix}"] = uri
            end
          end
        end
      end
    end
  end
end
