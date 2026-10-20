# frozen_string_literal: true

module Xmi0beBoundedByLabelsHelpers
  ASSOCIATIONS = %w[
    EAID_351EC738_E01B_45ff_B3E0_395258918C14
    EAID_CAA01CB7_69F5_49bf_82ED_F96AAB72CDD6
    EAID_AD628304_78EA_4e0b_B4AF_39769E39D20E
  ].freeze

  def self.result(path)
    document, diagram, connectors = source(path)
    legacy_connectors = without_umldi_bounds(connectors)
    [connectors.map(&:umldi_label_bounds), connectors.map(&:label_boxes),
     render_labels(document, diagram, connectors),
     render_labels(document, diagram, legacy_connectors)]
  end

  def self.source(path)
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    diagram = document.diagrams.first
    connectors = ASSOCIATIONS.map do |association_id|
      diagram.connectors.find { |connector| connector.relationship_ref == association_id }
    end
    [document, diagram, connectors]
  end

  def self.without_umldi_bounds(connectors)
    connectors.map { |connector| connector.dup.tap { |copy| copy.umldi_label_bounds = {} } }
  end

  def self.render_labels(document, diagram, connectors)
    render_diagram = diagram.dup
    render_diagram.connectors = connectors
    svg = Ea::Svg::EaEmitter::Document.new(
      render_diagram, model_index: document.index_by_id, document: document
    ).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']")
            .select { |node| node.text == "+boundedBy" }
            .map { |node| [node["x"], node["y"]] }
  end
end
