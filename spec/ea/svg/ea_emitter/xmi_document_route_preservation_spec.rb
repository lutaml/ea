# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "XMI document route corpus" do
  include QeaBridgeCorpusHelpers
  include XmiNativeArcHelpers
  include XmiDocumentRoutePreservationHelpers

  before(:context) { skip "plateau XMI unavailable" unless File.exist?(plateau_xmi_path) }
end

RSpec.describe Ea::Svg::EaEmitter::Document, "E7FFECEB native route" do
  include_context "XMI document route corpus"

  before(:context) { @scene = xmi_route_scene("73025C5A-08FC-47ff-AB2F-C7F79CF54B41") }

  it "keeps the native x=620, y=640..700 route" do
    path = xmi_document_connector_path(@scene, "E7FFECEB-996C-45b0-8E47-A56B4834C7DF", [[625, 165], [625, 225]])
    actual = xmi_route_geometry(path)
    native = xmi_native_route(@scene, [[625, 165], [625, 225]])

    expect(xmi_native_coordinates(actual[:endpoints], @scene[:shift])).to eq(native[:endpoints])
    expect(actual[:segment_count]).to eq(1)
    expect(actual[:arcs]).to be_empty
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "D147 native crossings" do
  include_context "XMI document route corpus"

  before(:context) { @scene = xmi_route_scene("E7AABA98-2450-4986-9736-DCCAF0108C50") }

  [
    [485, "A9F15FEA-A44A-488C-B8CF-CB097D4B009A", [[925, 396], [925, 522]], [925, 497]],
    [808, "691EB32D-B315-430F-BA1E-7A91E05BC70F", [[1086, 522], [1086, 455]], [1086, 497]]
  ].each do |id, guid, endpoints, crossing|
    it "keeps connector #{id} on its native vertical route and crossing" do
      actual = xmi_route_geometry(xmi_document_connector_path(@scene, guid, endpoints))
      native = xmi_native_route(@scene, endpoints)

      expect(native[:arcs]).to eq([crossing])
      aggregate_failures do
        expect(xmi_native_coordinates(actual[:endpoints], @scene[:shift])).to eq(native[:endpoints])
        expect(xmi_native_coordinates(actual[:arcs], @scene[:shift])).to eq(native[:arcs])
      end
    end
  end

  it "preserves connector 848 endpoints and both native crossings" do
    path = xmi_document_connector_path(@scene, "AD628304-78EA-4E0B-B4AF-39769E39D20E", [[1285, 1153], [656, 497]])
    actual = xmi_route_geometry(path)
    native = xmi_native_route(@scene, [[1285, 1153], [656, 497]])

    expect(native[:arcs]).to eq([[862, 497], [1285, 562]])
    expect(xmi_native_coordinates(actual[:endpoints], @scene[:shift])).to eq(native[:endpoints])
    expect(xmi_native_coordinates(actual[:arcs], @scene[:shift])).to eq(native[:arcs])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "D148 native crossings" do
  include_context "XMI document route corpus"

  before(:context) { @scene = xmi_route_scene("00C5C772-5A03-434f-BF30-AC37542A1AAC") }

  it "preserves all twelve native arc seats" do
    native = arc_end_seats(@scene[:native])

    expect(native.size).to eq(12)
    expect(xmi_native_coordinates(arc_end_seats(@scene[:svg]), @scene[:shift])).to eq(native)
  end
end
