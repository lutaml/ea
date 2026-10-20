# frozen_string_literal: true

require "tmpdir"

module XmiConnectorEndHelpers
  BASIC_XMI = File.expand_path("../fixtures/basic.xmi", __dir__)
  LINK_A = "EAID_1137B03A_C00A_443b_A3A8_D5CF6A7AFF13"
  OBJECT_A = "EAID_779FE88F_1C62_48fa_803E_B3C621A09C68"
  OBJECT_B = "EAID_FD9B2DCF_E737_471f_A86F_37BACFD69978"

  def connector_end_models(xmi_text, relationship_ref)
    diagram, connector = connector_in(xmi_text, relationship_ref)
    subjects = diagram.elements.to_h { |element| [element.id, element.model_element_ref] }
    [subjects[connector.source_element_ref], subjects[connector.target_element_ref]]
  end

  def basic_xmi_text
    File.read(BASIC_XMI)
  end

  def all_basic_connectors
    parse_xmi(basic_xmi_text).diagrams.flat_map(&:connectors)
  end

  def basic_with_duplicate_placement(subject)
    row = basic_xmi_text[/^\s*<element geometry="[^"]*" subject="#{subject}"[^\n]*\n/]
    basic_xmi_text.sub(row) { row + row }
  end

  def basic_with_source_duid_of(relationship_ref, duid)
    basic_xmi_text.sub(/(subject="#{relationship_ref}" style="[^"]*SOID=)\w+/) { "#{Regexp.last_match(1)}#{duid}" }
  end

  private

  def connector_in(xmi_text, relationship_ref)
    parse_xmi(xmi_text).diagrams.each do |diagram|
      connector = diagram.connectors.find { |candidate| candidate.relationship_ref == relationship_ref }
      return [diagram, connector] if connector
    end
  end

  def parse_xmi(xmi_text)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "model.xmi")
      File.write(path, xmi_text)
      Ea::Sources::Xmi::Adapter.from_path(path)
    end
  end
end
