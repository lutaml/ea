# frozen_string_literal: true

require "nokogiri"

# Native Enterprise Architect seats for the five real Property cases, read
# through the public XMI Adapter. Each slice shares its class rectangles with
# the native SVG at a constant translation (REGISTRATION: native = emitted + t).
module Issue135NativeSeatCases
  CASES = {
    "extent" => { file: "property-source-25-139-extent.xmi", mult: "0..1", t: [-25, -35],
                  role: [731, 364], stereo: [723, 376], mult_at: [778, 424] },
    "target" => { file: "property-source-89-889-target.xmi", mult: "0..*", t: [-25, -30],
                  role: [330, 176], stereo: [321, 188], mult_at: [220, 184] },
    "lod0MultiCurve" => { file: "property-source-117-273-lod0MultiCurve.xmi", mult: "0..1", t: [-25, -30],
                          role: [319, 171], stereo: [333, 183], mult_at: [373, 220] },
    "district" => { file: "property-source-54-892-district.xmi", mult: "0..*", t: [14, -30],
                    role: [870, 1510], stereo: [864, 1522], mult_at: [931, 1514] },
    "opening" => { file: "property-source-146-629-opening.xmi", mult: "0..*", t: [45, -30],
                   role: [312, 1077], stereo: [309, 1089], mult_at: [389, 1087] }
  }.freeze
end

RSpec.describe "Issue 135 Property source native seats (XMI)" do
  fixtures = File.expand_path("../../../fixtures/issue135_route_style", __dir__)

  Issue135NativeSeatCases::CASES.each do |name, data|
    it "seats the #{name} source role, Property stereotype and multiplicity at the native positions" do
      document = Ea::Sources::Xmi::Adapter.from_path(File.join(fixtures, data[:file]))
      svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                      document: document, frame: false).render
      texts = Nokogiri::XML(svg).remove_namespaces!.xpath("//text").to_h do |node|
        [node.text.strip, [node["x"].to_f, node["y"].to_f]]
      end
      native = lambda do |text|
        x, y = texts.fetch(text)
        [x + data[:t][0], y + data[:t][1]]
      end

      expect(native.call("+#{name}")).to eq(data[:role].map(&:to_f))
      expect(native.call("«property»")).to eq(data[:stereo].map(&:to_f))
      expect(native.call(data[:mult])).to eq(data[:mult_at].map(&:to_f))
    end
  end
end
