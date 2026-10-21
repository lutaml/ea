# frozen_string_literal: true

require "spec_helper"

# EA draws a NoteLink target-first with the double-back repeat
# ("M 313 561 L 174 591 M 313 561" in 9DA6C553); the stored waypoints run
# source (the note) to target, so the emitter reverses them. Checked on the
# three NoteLink diagrams 9DA6C553, 926AFE38 and 676B9C9A in both formats.
RSpec.describe Ea::Svg::EaEmitter::Connectors, "NoteLink path direction" do
  include ConnectorBridgesHelpers

  def path_for_type(type, points)
    connector = bridge_connector("c", points, connector_type: type)
    bridge_paths(bridge_diagram([connector])).first
  end

  it "draws a two-point NoteLink target-first with the repeated move" do
    expect(path_for_type("NoteLink", [[199, 621], [338, 591]]))
      .to eq("M 338 591 L 199 621 M 338 591")
  end

  it "draws a two-point Package connector the same way" do
    expect(path_for_type("Package", [[139, 322], [341, 233]]))
      .to eq("M 341 233 L 139 322 M 341 233")
  end

  it "keeps source-first single lines for other connector types" do
    expect(path_for_type("Association", [[199, 621], [338, 591]]))
      .to eq("M 199 621 L 338 591")
  end

  it "keeps a bent NoteLink as a plain source-first polyline" do
    expect(path_for_type("NoteLink", [[0, 0], [0, 50], [80, 50]]))
      .to eq("M 0 0 L 0 50 L 80 50")
  end
end
