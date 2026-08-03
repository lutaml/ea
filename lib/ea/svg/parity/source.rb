# frozen_string_literal: true

require "xmi"

module Ea
  module Svg
    module Parity
      # Loads an EA model Document from any supported source file
      # (`.qea`, `.xmi`). Used by the bench task to keep file-format
      # dispatch in one place.
      class Source
        EXTENSIONS = {
          ".qea" => :qea,
          ".xmi" => :xmi
        }.freeze

        attr_reader :path

        def initialize(path)
          @path = path
        end

        def self.detect(path)
          ext = File.extname(path).downcase
          EXTENSIONS[ext] ||
            raise(ArgumentError, "unsupported source: #{path} (ext=#{ext})")
        end

        def load
          case self.class.detect(path)
          when :qea then load_qea
          when :xmi then load_xmi
          end
        end

        def document
          load
        end

        def format
          self.class.detect(path)
        end

        private

        def load_qea
          raise NotImplementedError, "QEA Document loading not yet wired into bench"
        end

        def load_xmi
          root = ::Xmi::Sparx::Root.parse_xml(File.read(path))
          Ea::Sources::Xmi::Adapter.new(root, path).to_document
        end
      end
    end
  end
end
