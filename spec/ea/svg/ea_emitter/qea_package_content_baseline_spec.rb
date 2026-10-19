# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA package content baselines" do
  include QeaPackageTabWidthHelpers

  [
    ["ArcGISWorkspace_template", "7D960BD8-65D8-4934-9C11-4EF860DD8FBA",
     "Spatial References", [["MySpatialReference", 15]]],
    ["basic", "84352F1A-195B-411b-9552-5BFC40BF90B5",
     "Package B", [["Class A", 15], ["Class B", 31]]],
    ["test", "F4C23F9E-DD74-4fed-B75D-AD3C6448BA24",
     "Test Schema", [["CodeList", 15], ["DataType", 31], ["DataType2", 47],
                     ["Enumeration", 63], ["FeatureType1", 79], ["FeatureType2", 95],
                     ["NilUnion", 111], ["Union", 127]]]
  ].each do |fixture, diagram_id, package_name, expected_rows|
    it "places #{package_name} contents below its native package tab" do
      document = package_width_document(fixture)
      xml = Nokogiri::XML("<svg>#{package_elements(document, diagram_id).render}</svg>")
      shape = xml.xpath("//g[polygon][text]").find { |group| group.css("text").last.text == package_name }
      body_top = shape.css("polygon").first["points"].split[1].to_f
      package_x = shape.css("text").last["x"].to_f
      expected_rows.each do |name, offset|
        matches = xml.css("text").select { |text| text.text == "+ #{name}" }
        expect(matches.length).to eq(1)
        expect(matches.first["y"].to_f).to eq(body_top + offset)
        expect(matches.first["x"].to_f).to eq(package_x + 18)
      end
    end
  end
end

RSpec.describe "Package content tab geometry controls" do
  include PackageContentGeometryHelpers
  let(:bounds) { Ea::Model::Bounds.new(x: 35, y: 60, width: 134, height: 174) }

  it "uses the rendered tab height across font sizes, units and stereotype rows" do
    [
      ["Cambria", 7, "pt", nil, 19],
      ["Cambria", 7, "pt", "applicationSchema", 34],
      ["Carlito", 9, "pt", nil, 22],
      ["Carlito", 9, "pt", "applicationSchema", 40],
      ["Carlito", 9, "px", "applicationSchema", 36]
    ].each do |family, size, unit, stereotype, tab_height|
      context = package_content_geometry_context(bounds, [family, size, unit], stereotype)
      body_top = package_content_body_top(context, stereotype)
      contents = Nokogiri::XML(Ea::Svg::EaEmitter::Compartment::PackageContents.render(context))

      expect(body_top).to eq(60 + tab_height)
      expect(contents.at_css("text")["y"].to_f).to eq(body_top + 15)
      expect(contents.at_css("text")["x"].to_f).to eq(58)
      expect(contents.at_css("rect")["y"].to_f).to eq(body_top + 4)
    end
  end

  it "omits contents when rows are absent" do
    [nil, []].each do |rows|
      context = Ea::Svg::EaEmitter::RenderContext.new(package_content_lines: rows)
      expect(Ea::Svg::EaEmitter::Compartment::PackageContents.render(context)).to be_nil
    end
  end
end
