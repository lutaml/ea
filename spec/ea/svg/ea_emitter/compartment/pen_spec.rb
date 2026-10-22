# frozen_string_literal: true

require "spec_helper"

# Every compartment declares the pen its first group leaves behind; that
# declaration must agree with the stroke style the compartment actually draws.
RSpec.describe Ea::Svg::EaEmitter::Compartment do
  let(:style_pen) { /stroke-linecap:(\w+);stroke-linejoin:(\w+)/ }
  let(:document) { Ea::Sources::Qea::Adapter.from_path(File.expand_path("../../../../fixtures/basic.qea", __dir__)) }

  def painted_in(document)
    painted = []
    allow(described_class).to receive(:paint_all).and_wrap_original do |original, context|
      original.call(context).tap { |layers| painted.concat(layers) }
    end
    document.diagrams.each do |diagram|
      Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    end
    painted
  end

  it "declares the pen found in the first group of every rendered compartment" do
    painted = painted_in(document)

    expect(painted).not_to be_empty
    expect(painted.map { |layer| [layer.svg.match(style_pen)&.captures, layer.pen] })
      .to all(satisfy { |drawn, declared| drawn == declared })
  end

  it "lets a ShapeScript stereotype icon leave the previous pen in force" do
    expect(described_class::StereotypeIcon.pen(nil)).to be_nil
  end
end
