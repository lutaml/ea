# frozen_string_literal: true

module Ea
  module Qea
    module Models
      class EaObject < BaseModel
        attribute :ea_object_id, Lutaml::Model::Type::Integer
        attribute :object_type, Lutaml::Model::Type::String
        attribute :diagram_id, Lutaml::Model::Type::Integer
        attribute :name, Lutaml::Model::Type::String
        attribute :alias, Lutaml::Model::Type::String
        attribute :author, Lutaml::Model::Type::String
        attribute :version, Lutaml::Model::Type::String
        attribute :note, Lutaml::Model::Type::String
        attribute :package_id, Lutaml::Model::Type::Integer
        attribute :stereotype, Lutaml::Model::Type::String
        attribute :ntype, Lutaml::Model::Type::Integer
        attribute :complexity, Lutaml::Model::Type::String
        attribute :effort, Lutaml::Model::Type::Integer
        attribute :style, Lutaml::Model::Type::String
        attribute :backcolor, Lutaml::Model::Type::Integer
        attribute :borderstyle, Lutaml::Model::Type::Integer
        attribute :borderwidth, Lutaml::Model::Type::Integer
        attribute :fontcolor, Lutaml::Model::Type::Integer
        attribute :bordercolor, Lutaml::Model::Type::Integer
        attribute :createddate, Lutaml::Model::Type::String
        attribute :modifieddate, Lutaml::Model::Type::String
        attribute :status, Lutaml::Model::Type::String
        attribute :abstract, Lutaml::Model::Type::String
        attribute :tagged, Lutaml::Model::Type::Integer
        attribute :pdata1, Lutaml::Model::Type::String
        attribute :pdata2, Lutaml::Model::Type::String
        attribute :pdata3, Lutaml::Model::Type::String
        attribute :pdata4, Lutaml::Model::Type::String
        attribute :pdata5, Lutaml::Model::Type::String
        attribute :concurrency, Lutaml::Model::Type::String
        attribute :visibility, Lutaml::Model::Type::String
        attribute :persistence, Lutaml::Model::Type::String
        attribute :cardinality, Lutaml::Model::Type::String
        attribute :gentype, Lutaml::Model::Type::String
        attribute :genfile, Lutaml::Model::Type::String
        attribute :header1, Lutaml::Model::Type::String
        attribute :header2, Lutaml::Model::Type::String
        attribute :phase, Lutaml::Model::Type::String
        attribute :scope, Lutaml::Model::Type::String
        attribute :genoption, Lutaml::Model::Type::String
        attribute :genlinks, Lutaml::Model::Type::String
        attribute :classifier, Lutaml::Model::Type::Integer
        attribute :ea_guid, Lutaml::Model::Type::String
        attribute :parentid, Lutaml::Model::Type::Integer
        attribute :runstate, Lutaml::Model::Type::String
        attribute :classifier_guid, Lutaml::Model::Type::String
        attribute :tpos, Lutaml::Model::Type::Integer
        attribute :isroot, Lutaml::Model::Type::Integer
        attribute :isleaf, Lutaml::Model::Type::Integer
        attribute :isspec, Lutaml::Model::Type::Integer
        attribute :isactive, Lutaml::Model::Type::Integer
        attribute :stateflags, Lutaml::Model::Type::String
        attribute :packageflags, Lutaml::Model::Type::String
        attribute :multiplicity, Lutaml::Model::Type::String
        attribute :styleex, Lutaml::Model::Type::String
        attribute :actionflags, Lutaml::Model::Type::String
        attribute :eventflags, Lutaml::Model::Type::String

        COLUMN_MAP = {
          "Object_ID" => :ea_object_id,
          "Object_Type" => :object_type,
          "Diagram_ID" => :diagram_id,
          "Name" => :name,
          "Alias" => :alias,
          "Author" => :author,
          "Version" => :version,
          "Note" => :note,
          "Package_ID" => :package_id,
          "Stereotype" => :stereotype,
          "NType" => :ntype,
          "Complexity" => :complexity,
          "Effort" => :effort,
          "Style" => :style,
          "BackColor" => :backcolor,
          "BorderStyle" => :borderstyle,
          "BorderWidth" => :borderwidth,
          "Fontcolor" => :fontcolor,
          "Bordercolor" => :bordercolor,
          "CreatedDate" => :createddate,
          "ModifiedDate" => :modifieddate,
          "Status" => :status,
          "Abstract" => :abstract,
          "Tagged" => :tagged,
          "PDATA1" => :pdata1,
          "PDATA2" => :pdata2,
          "PDATA3" => :pdata3,
          "PDATA4" => :pdata4,
          "PDATA5" => :pdata5,
          "Concurrency" => :concurrency,
          "Visibility" => :visibility,
          "Persistence" => :persistence,
          "Cardinality" => :cardinality,
          "GenType" => :gentype,
          "GenFile" => :genfile,
          "Header1" => :header1,
          "Header2" => :header2,
          "Phase" => :phase,
          "Scope" => :scope,
          "GenOption" => :genoption,
          "GenLinks" => :genlinks,
          "Classifier" => :classifier,
          "ea_guid" => :ea_guid,
          "ParentID" => :parentid,
          "RunState" => :runstate,
          "Classifier_guid" => :classifier_guid,
          "TPos" => :tpos,
          "IsRoot" => :isroot,
          "IsLeaf" => :isleaf,
          "IsSpec" => :isspec,
          "IsActive" => :isactive,
          "StateFlags" => :stateflags,
          "PackageFlags" => :packageflags,
          "Multiplicity" => :multiplicity,
          "StyleEx" => :styleex,
          "ActionFlags" => :actionflags,
          "EventFlags" => :eventflags,
        }.freeze

        def self.column_map
          COLUMN_MAP
        end

        def self.primary_key_column
          :ea_object_id
        end

        def self.table_name
          "t_object"
        end

        def abstract?
          abstract == "1"
        end

        def uml_class?
          object_type == "Class"
        end

        def interface?
          object_type == "Interface"
        end

        def component?
          object_type == "Component"
        end

        def package?
          object_type == "Package"
        end

        def enumeration?
          object_type == "Enumeration"
        end

        def data_type?
          object_type == "DataType"
        end

        def instance?
          object_type == "Object"
        end

        def root?
          isroot == 1
        end

        def leaf?
          isleaf == 1
        end

        # Resolve the transformer registry key for this object's type.
        # Considers both object_type and stereotype (e.g., a Class with
        # stereotype "enumeration" transforms as an enum).
        #
        # EA object types that have no UML model equivalent return nil and
        # are skipped during transformation:
        #
        #   Text           — diagram text annotation box. A rendering hint,
        #                    not a model element. Currently dropped; its
        #                    content is not preserved in the UML document.
        #                    (Faithful mapping to UML Comment is pending a
        #                    `comments` collection on Package.)
        #
        #   ProxyConnector — EA-internal stub representing a connector that
        #                    crosses package boundaries. Structural plumbing
        #                    with no UML equivalent. Dropped.
        #
        #   Note           — diagram note. Same situation as Text: rendering
        #                    hint, not a model element. Dropped.
        #
        # @return [Symbol, nil] Registry key or nil if not a UML model element
        def transformer_type
          if enumeration? || stereotype_is?("enumeration")
            :enumeration
          elsif data_type?
            :data_type
          elsif uml_class? || interface?
            :class
          elsif instance?
            :instance
          end
        end

        def stereotype_is?(expected)
          return false unless stereotype

          stereotype.downcase == expected
        end

        # @return [Integer] tpos for tree-position ordering
        def sort_position
          tpos || 0
        end
      end
    end
  end
end
