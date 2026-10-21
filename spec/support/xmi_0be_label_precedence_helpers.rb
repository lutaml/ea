# frozen_string_literal: true

require "nokogiri"
require "tempfile"

module Xmi0beLabelPrecedenceHelpers
  def bounded_by_connector(box: nil, remove_bounds: false)
    xml = bounded_by_xml(box, remove_bounds)
    Tempfile.create(["0be-label-precedence", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      Xmi0beBoundedByLabelsHelpers.source(file.path).last.first
    end
  end

  def bounded_by_xml(box, remove_bounds)
    xml = Nokogiri::XML(File.read(fixtures_path("issue135_route_style/0be-boundedby-umldi.xmi")))
    association = Xmi0beBoundedByLabelsHelpers::ASSOCIATIONS.first
    if box
      placement = xml.at_xpath("//*[@subject='#{association}']")
      placement["geometry"] += "$#{box}=CX=0:CY=0:OX=0:OY=0;"
    end
    xml.xpath("//*[@modelElement='#{association}']/ownedElement").each(&:remove) if remove_bounds
    xml
  end

  def bounded_by_route(connector)
    connector.waypoints.map { |point| [point.position.x, point.position.y] }
  end
end
