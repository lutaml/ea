# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Association-end attribute compartments" do
  include Issue135AssociationAttributeFilterHelpers

  let(:document) { issue135_attribute_filter_document }

  it "omits A9FE9E6F undrawn association rows and drawn ends from emitted compartments" do
    rows = issue135_attribute_filter_texts(document).select { |text| text.include?(": ") && !text.start_with?("+") }

    # Native A9FE9E6F omits Zone.boundary, Zone.urbanParkAttribute and
    # UrbanFacility.threeDimensionalExtent despite their undrawn associations.
    expect(rows).to contain_exactly("boundary: String", "name: String")
  end

  it "preserves XMI association-end properties for emitted connector roles and multiplicities" do
    properties = document.classifiers.first.properties.dup
    texts = issue135_attribute_filter_texts(document)

    # The association refers to classifiers, so this role can only come from
    # the retained association_id property lookup, not a property-id endpoint.
    expect(texts).to include("+drawnBoundary: Boundary", "0..*")
    expect(document.classifiers.first.properties).to eq(properties)
    expect(document.property_by_id("property-boundary-association").name).to eq("boundary")
  end

  it "keeps the exclusion keyword compatible for absent, empty and populated diagram sets" do
    classifier = document.classifiers.first
    [nil, [], ["drawn-association"]].each do |drawn_ids|
      lines = Ea::Svg::EaEmitter::Element::AttributeRenderer.lines_for(
        classifier, exclude_association_ids: drawn_ids
      )

      expect(lines).to eq(["+ boundary: String"])
    end
  end
end
