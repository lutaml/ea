# frozen_string_literal: true

require "spec_helper"

# Consolidated spec for the remaining QEA models not covered by
# auxiliary_models_spec.rb. Each model gets table_name,
# primary_key_column, and from_db_row coverage.
RSpec.describe "Ea::Qea remaining models (table + pk)" do
  # [class, table_name, primary_key_column]
  # Some EA lookup tables (complexity_type, connector_type, etc.)
  # have a string-column primary key named after the table's
  # purpose rather than an integer surrogate.
  REMAINING_MODELS = [
    [Ea::Qea::Models::EaAttributeTag,   "t_attributetag",     :property_id],
    [Ea::Qea::Models::EaAuthor,         "t_authors",          :author_id],
    [Ea::Qea::Models::EaComplexityType, "t_complexitytypes",  "Complexity"],
    [Ea::Qea::Models::EaConnectorType,  "t_connectortypes",   "Connector_Type"],
    [Ea::Qea::Models::EaConstraintType, "t_constrainttypes",  "Constraint"],
    [Ea::Qea::Models::EaDatatype,       "t_datatypes",        :datatypeid],
    [Ea::Qea::Models::EaDiagramLink,    "t_diagramlinks",     :instance_id],
    [Ea::Qea::Models::EaDiagramObject,  "t_diagramobjects",   :instance_id],
    [Ea::Qea::Models::EaDiagramType,    "t_diagramtypes",     "Diagram_Type"],
    [Ea::Qea::Models::EaGlossary,       "t_glossary",         :glossary_id],
    [Ea::Qea::Models::EaImage,          "t_image",            :image_id],
    [Ea::Qea::Models::EaList,           "t_lists",            :list_id],
    [Ea::Qea::Models::EaObjectProperty, "t_objectproperties", :property_id],
    [Ea::Qea::Models::EaObjectType,     "t_objecttypes",      "Object_Type"],
    [Ea::Qea::Models::EaPhase,          "t_phase",            :phase_id],
    [Ea::Qea::Models::EaStatusType,     "t_statustypes",      "Status"],
    [Ea::Qea::Models::EaTaggedValue,    "t_taggedvalue",      :property_id],
    [Ea::Qea::Models::EaVersion,        "t_versions",         :version_id],
  ].freeze

  it "covers 18 models" do
    expect(REMAINING_MODELS.size).to eq(18)
  end

  REMAINING_MODELS.each do |model_class, expected_table, expected_pk|
    describe model_class.name do
      it "declares the correct table_name" do
        expect(model_class.table_name).to eq(expected_table)
      end

      it "declares the correct primary_key_column" do
        expect(model_class.primary_key_column).to eq(expected_pk)
      end

      it "is a BaseModel descendant" do
        expect(model_class.ancestors).to include(Ea::Qea::Models::BaseModel)
      end

      it "responds to from_db_row" do
        expect(model_class).to respond_to(:from_db_row)
      end
    end
  end

  # EaStereotype has nil pk — verified separately.
  describe Ea::Qea::Models::EaStereotype do
    it "declares t_stereotypes" do
      expect(described_class.table_name).to eq("t_stereotypes")
    end

    it "declares nil primary_key_column (no single-column pk)" do
      expect(described_class.primary_key_column).to be_nil
    end

    it "is a BaseModel descendant" do
      expect(described_class.ancestors).to include(Ea::Qea::Models::BaseModel)
    end
  end
end
