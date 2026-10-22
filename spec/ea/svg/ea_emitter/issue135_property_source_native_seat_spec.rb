# frozen_string_literal: true

require "nokogiri"

# Native Enterprise Architect seats for the five real Property cases, read
# through the public XMI Adapter. Registration (native = emitted + t) is pinned
# per slice by the source and target class rectangles, identified by class
# name and size in both SVGs, never by the labels under test.
module Issue135NativeSeatCases
  CASES = {
    "extent" => { file: "property-source-25-139-extent.xmi", diagram: "EAID_70C77F92_5614_4b22_8C8E_67859F59D8FD",
                  mult: "0..1", t: [-25, -35], role: [731, 364], stereo: [723, 376], mult_at: [778, 424],
                  classes: [["Polygon", 111, 70], ["_ReliefComponent", 270, 71]] },
    "target" => { file: "property-source-89-889-target.xmi", diagram: "EAID_BDA613D8_402A_475a_AA15_683D88FD3D23",
                  mult: "0..*", t: [-25, -30], role: [330, 176], stereo: [321, 188], mult_at: [220, 184],
                  classes: [["_CityObject", 330, 142], ["_UrbanFunction", 287, 465]] },
    "lod0MultiCurve" => { file: "property-source-117-273-lod0MultiCurve.xmi",
                          diagram: "EAID_B53E76CD_A0F2_4e2f_B3AB_796D85964EF2", mult: "0..1", t: [-25, -30],
                          role: [319, 171], stereo: [333, 183], mult_at: [373, 220],
                          classes: [["MultiCurve", 190, 80], ["_UrbanFunction", 269, 387]] },
    "district" => { file: "property-source-54-892-district.xmi", diagram: "EAID_2C8DD882_8DEA_4065_89F8_DDA796AA0C85",
                    mult: "0..*", t: [14, -30], role: [870, 1510], stereo: [864, 1522], mult_at: [931, 1514],
                    classes: [["District", 375, 394], ["DistrictDevelopmentPlan", 390, 139]] },
    "opening" => { file: "property-source-146-629-opening.xmi", diagram: "EAID_30D62231_110F_44e8_9C06_6FCDCBA53A09",
                   mult: "0..*", t: [45, -30], role: [312, 1077], stereo: [309, 1089], mult_at: [389, 1087],
                   classes: [["_Opening", 120, 80], ["_BoundarySurface", 120, 161]] }
  }.freeze

  def self.parse_svg(text)
    Nokogiri::XML(text).remove_namespaces!
  end

  def self.emitted_svg(path)
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    parse_svg(Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                        document: document, frame: false, content_anchor: false).render)
  end

  def self.numbers(node, *names)
    names.map { |name| node[name].to_f }
  end

  def self.class_rect(svg, name, size)
    texts = svg.xpath("//text").select { |t| t.text.strip.split("::").last == name }
    svg.xpath("//rect").filter_map { |rect| rect_origin(rect, size, texts) }
  end

  def self.rect_origin(rect, size, texts)
    x, y, width, height = numbers(rect, "x", "y", "width", "height")
    return unless [width, height] == size.map(&:to_f)

    [x, y] if texts.any? { |t| inside?(numbers(t, "x", "y"), [x, y, x + width, y + height]) }
  end

  def self.shifts(emitted_svg, native_svg, classes)
    classes.map do |class_name, *size|
      emitted = class_rect(emitted_svg, class_name, size)
      expected = class_rect(native_svg, class_name, size)
      [emitted.size, expected.size, [expected[0][0] - emitted[0][0], expected[0][1] - emitted[0][1]]]
    end
  end

  def self.inside?(point, box)
    point[0].between?(box[0], box[2]) && point[1].between?(box[1], box[3])
  end
end

RSpec.describe "Issue 135 Property source native seats (XMI)" do
  fixtures = File.expand_path("../../../fixtures/issue135_route_style", __dir__)
  # Directory of EA's native EAID_<GUID>.svg exports for the PLATEAU model.
  native_dir = ENV.fetch("EA_PLATEAU_NATIVE_SVG_DIR") do
    File.expand_path("../../../../../lutaml/examples/xmi/Images", __dir__)
  end

  Issue135NativeSeatCases::CASES.each do |name, data|
    describe name do
      let(:svg) { Issue135NativeSeatCases.emitted_svg(File.join(fixtures, data[:file])) }

      it "registers the slice to the native SVG by both endpoint class rectangles" do
        native_path = File.join(native_dir, "#{data[:diagram]}.svg")
        skip "native SVG unavailable" unless File.exist?(native_path)
        native = Issue135NativeSeatCases.parse_svg(File.read(native_path))

        shifts = Issue135NativeSeatCases.shifts(svg, native, data[:classes])
        expect(shifts).to eq([[1, 1, data[:t].map(&:to_f)]] * 2)
      end

      it "seats the one source role with its own Property stereotype and multiplicity at native positions" do
        roles = svg.xpath("//text").select { |t| t.text.strip == "+#{name}" }
        expect(roles.size).to eq(1)
        cluster = roles.first.parent.xpath("text")
        expect(cluster.map { |t| t.text.strip }).to eq(["+#{name}", "«property»", data[:mult]])

        seats = cluster.map { |t| [t["x"].to_f + data[:t][0], t["y"].to_f + data[:t][1]] }
        expect(seats).to eq([data[:role], data[:stereo], data[:mult_at]].map { |seat| seat.map(&:to_f) })
      end
    end
  end
end
