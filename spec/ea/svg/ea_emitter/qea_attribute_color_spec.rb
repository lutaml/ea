# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA attribute text color" do
  include TestDatabaseHelper
  include QeaAttributeOrderHelpers

  let(:document) { qea_attribute_order_document([["alpha", 0]], styleex: "Theme=:119;SuppressFOC=1;") }

  let(:svg) do
    Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                              document: document, frame: false, content_anchor: false).render
  end

  let(:attribute_fills) do
    texts = Nokogiri::XML(svg).remove_namespaces!.css("text").select { |t| t.text.match?(/\A\+|: String/) }
    texts.map { |t| t["style"][/fill:(#\h{6})/, 1] }.uniq
  end

  it "renders theme :119 attribute rows black, as the EA reference does" do
    expect(attribute_fills).to eq(["#000000"])
  end

  it "keeps a colour a theme explicitly declares for attribute text" do
    custom = Ea::Theme::Registry.lookup("119").with(id: "119_attr", attribute_text_color: "#123456")
    document.diagrams.first.theme = custom
    expect(attribute_fills).to eq(["#123456"]) # lazy lets render after the theme is set
  end
end
