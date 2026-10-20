# frozen_string_literal: true

require "tempfile"

module XmiAssociationClassTetherHelpers
  TETHER_FIXTURE = File.expand_path("../fixtures/association_class_tether_metadata.xmi", __dir__)
  TETHER_PROXIES = %w[EAID_53ED6341_10CF_4e13_A4F9_CC4271FD2997 EAID_DD2DE7C9_00AF_426a_9CF2_AAE1FC22F25A].freeze

  # The saved tether connector of the fixture diagram after the XMI import,
  # with the fixture text rewritten by each [from, to] pair first.
  def tether_connector(*replacements)
    xml = replacements.reduce(File.read(TETHER_FIXTURE)) { |text, (from, to)| text.gsub(from, to) }
    Tempfile.create(["tether", ".xmi"]) do |file|
      file.write(xml)
      file.flush
      Ea::Sources::Xmi::Adapter.from_path(file.path).diagrams.first.connectors.first
    end
  end

  def proxy_classifier(value)
    TETHER_PROXIES.map do |proxy|
      head = %(xmi:idref="#{proxy}" xmi:type="uml:ProxyConnector" name="ProxyConnector" scope="public")
      [%(#{head} classifier="EAID_9BC16EE3_0B50_4f3d_A7E8_A84D12AE484F"), "#{head}#{value}"]
    end
  end

  def points(connector)
    connector.waypoints.map { |waypoint| [waypoint.position.x, waypoint.position.y] }
  end
end
