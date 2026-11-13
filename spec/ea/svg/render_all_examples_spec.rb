# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"

# Regression for #51: every diagram in every committed example QEA must
# render without raising (e.g. TextRenderer TypeError on nil).
RSpec.describe "Rendering every committed example diagram" do
  root = File.expand_path("../../..", __dir__)

  Dir.glob(File.join(root, "examples", "qea", "*.qea")).each do |path|
    describe File.basename(path) do
      let(:qea_doc) { Ea::Sources::Qea::Adapter.from_path(path) }

      it "renders every diagram to a non-empty svg" do
        qea_doc.diagrams.each do |diagram|
          svg = nil
          expect do
            svg = Ea::Svg::EaEmitter::Document.new(
              diagram, model_index: qea_doc.index_by_id,
                       document: qea_doc, frame: true
            ).render
          end.not_to raise_error, "render failed for #{diagram.name.inspect}"

          root_el = Nokogiri::XML(svg).root
          expect(root_el&.name).to eq("svg")
          expect(root_el.element_children).not_to be_empty,
                                                  "empty svg for #{diagram.name.inspect}"
        end
      end
    end
  end
end
