# frozen_string_literal: true

module XmiLandpriceAttributeOrderHelpers
  LANDPRICE_GUID = "EAID_933DD8AE_621F_4f20_A779_1AA45CCFD6EA"
  ORDERED_PROPERTY_NAMES = %w[buildingCoverageRate attributeHistory].freeze

  def landprice_attribute_order_document
    Ea::Sources::Xmi::Adapter.from_path("spec/fixtures/xmi_landprice_attribute_order/landprice.xmi")
  end

  def landprice_rendered_property_names(document)
    diagram = document.diagrams.first
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: false, content_anchor: false).render
    Nokogiri::XML(svg).remove_namespaces!.css("text").map(&:text)
            .select { |text| ORDERED_PROPERTY_NAMES.any? { |name| text.include?(name) } }
            .map { |text| text.split(":", 2).first }
  end
end
