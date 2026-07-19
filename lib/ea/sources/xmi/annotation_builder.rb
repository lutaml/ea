# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Builds Ea::Model::Annotation instances from XMI owned_comment
      # elements. Each non-empty comment body becomes one Annotation.
      class AnnotationBuilder
        attr_reader :owner_id

        def initialize(owner_id)
          @owner_id = owner_id
        end

        # Extract comments from a source element. Only PackagedElement-
        # derived types (Class, Package, Association, etc.) carry
        # owned_comment in the XMI schema; attribute/operation/literal
        # do not. We dispatch on type rather than poking at the
        # method, so unknown element types just yield no annotations.
        def self.from_element(element, owner_id, kind: "documentation")
          comments = comments_on(element)
          from_comments(comments, owner_id, kind: kind)
        end

        def self.from_comments(comments, owner_id, kind: "documentation")
          Array(comments).map { |c| new(owner_id).build(kind, c.body) }
        end

        def self.comments_on(element)
          return [] unless element.is_a?(::Xmi::Uml::PackagedElement)

          element.owned_comment
        end

        def build(kind, body, author: nil, modified_date: nil)
          return nil if body.nil? || body.empty?

          Ea::Model::Annotation.new(
            id: IdNormalizer.synthetic_id(owner_id, kind),
            kind: kind,
            body: body,
            author: author,
            modified_date: modified_date
          )
        end
      end
    end
  end
end
