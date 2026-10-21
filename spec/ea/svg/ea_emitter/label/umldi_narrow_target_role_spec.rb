# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "tmpdir"

# 159E9DA0 and 90BCA409 draw "+endPoint" (46 wide) over a 49 wide UMLDI
# box set by the 48 wide stereotype; EA centres the narrower role over it.
RSpec.describe "A Property target role narrower than its stereotype" do
  let(:source_path) { fixtures_path("issue135_multiplicity/diagonal_property_target.xmi") }
  let(:texts) do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "end_point.xmi")
      File.write(path, File.read(source_path).gsub("referencePoint", "endPoint"))
      document = Ea::Sources::Xmi::Adapter.from_path(path)
      svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                      document: document).render
      Nokogiri::XML(svg).xpath("//*[local-name()='text']").to_h { |n| [n.text, n["x"].to_f] }
    end
  end

  it "seats the stereotype on the saved box edge and the role one pixel right of it" do
    expect(texts.slice("+endPoint", "«property»")).to eq("+endPoint" => 131.0, "«property»" => 130.0)
  end

  it "keeps a role as wide as the stereotype on the box edge" do
    document = Ea::Sources::Xmi::Adapter.from_path(source_path)
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document).render
    x = Nokogiri::XML(svg).xpath("//*[local-name()='text']").to_h { |n| [n.text, n["x"].to_f] }

    expect(x["+referencePoint"]).to eq(x["«property»"] - 11.0)
  end
end
