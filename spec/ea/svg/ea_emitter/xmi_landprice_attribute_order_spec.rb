# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI stored classifier attribute order" do
  include XmiLandpriceAttributeOrderHelpers

  it "renders the source ownedAttribute sequence through the public pipeline" do
    document = landprice_attribute_order_document
    classifier_element = document.diagrams.first.elements.find do |element|
      element.model_element_ref == XmiLandpriceAttributeOrderHelpers::LANDPRICE_GUID
    end

    expect(landprice_rendered_property_names(document)).to eq(
      XmiLandpriceAttributeOrderHelpers::ORDERED_PROPERTY_NAMES
    )
    expect(classifier_element.style[:stored_attribute_order]).to be(true)
  end

  it "retains alphabetical rendering without the XMI provenance flag" do
    document = landprice_attribute_order_document
    document.diagrams.first.elements.find do |element|
      element.model_element_ref == XmiLandpriceAttributeOrderHelpers::LANDPRICE_GUID
    end.style.delete(:stored_attribute_order)

    expect(landprice_rendered_property_names(document)).to eq(
      XmiLandpriceAttributeOrderHelpers::ORDERED_PROPERTY_NAMES.sort
    )
  end
end
