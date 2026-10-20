# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "XMI connector route style propagation" do
  include XmiConnectorRouteStyleHelpers

  let(:expected_style) { { mode: "3", lwidth: "2", tree: "LH" } }
  let(:expected_route) { [[918, 731], [918, 230], [1100, 230]] }

  it "uses saved label routing metadata on the original EA Path branch" do
    connector, role = rendered_role_seat(fixtures_path("issue135_route_style/4eb-role-seat-path.xmi"))

    expect(connector.style.to_h).to eq(expected_style)
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(expected_route)
    expect(connector.style.to_h).not_to have_key(:umldi_route)
    # The LH Property seat uses the saved LLT box and the QEA-derived
    # left-seat equation; (185,105) is not asserted as a native coordinate.
    expect([role["x"], role["y"], role["textLength"]]).to eq(["185.00", "105.00", "111"])
    expect(role["style"]).to include("font-family:Cambria", "font-size:7pt")
  end

  it "keeps UMLDI waypoints authoritative while applying their saved label style" do
    connector, role = rendered_role_seat(fixtures_path("issue135_route_style/4eb-role-seat-umldi.xmi"))

    expect(connector.style.to_h).to eq(expected_style.merge(umldi_route: true))
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(expected_route)
    expect([role["x"], role["y"], role["textLength"]]).to eq(["185.00", "105.00", "111"])
  end

  it "leaves the ordinary connector label path usable without route metadata" do
    connector, role = rendered_role_seat(fixtures_path("issue135_route_style/4eb-role-seat-generic.xmi"))

    expect(connector.style.to_h).not_to include(:mode, :lwidth, :tree)
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[918, 731], [918, 230], [1160, 190]])
    expect(role.text).to eq("+indoorOpeningAttribute")
  end
end
