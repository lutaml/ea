# frozen_string_literal: true

module MidpointNameHelpers
  def midpoint_name_renderer(options)
    described_class.new(
      canvas: nil, model_index: model_index, font_family: options.fetch(:family, "Cambria"),
      font_size: options.fetch(:size, 7), font_unit: options.fetch(:unit, "pt")
    )
  end

  def named_midpoint_nodes(record, **options)
    relation = association
    relation.name = record[:name]
    relation.stereotype = options[:stereotype]
    connector = Ea::Model::DiagramConnector.new(
      id: "name", relationship_ref: relation.id,
      label_boxes: { lmt: options.fetch(:box, record[:box]) },
      is_substitutable: options.fetch(:substitutable, false)
    )
    output = midpoint_name_renderer(options).text_for(connector, record[:points])
    Nokogiri::XML("<svg>#{output}</svg>").css("text")
  end
end
