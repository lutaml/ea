# frozen_string_literal: true

require "spec_helper"

# AB281AC1: _UrbanFunction is placed without LWth, so its border width comes
# from the model element's <style appearance>, as t_object.BorderWidth does in QEA.
RSpec.describe Ea::Sources::Xmi::DiagramBuilder::ElementBorders do
  def root_with(appearance)
    element = %(<element xmi:idref="EAID_A" xmi:type="uml:Class" name="A"><style appearance="#{appearance}"/></element>)
    ns = "http://schema.omg.org/spec/XMI/2.1"
    extension = %(<xmi:Extension extender="Enterprise Architect"><elements>#{element}</elements></xmi:Extension>)
    Xmi::Sparx::Root.parse_xml(%(<xmi:XMI xmlns:xmi="#{ns}">#{extension}</xmi:XMI>))
  end

  it "reads BorderWidth from the element appearance" do
    root = root_with("BackColor=16764159;BorderColor=-1;BorderWidth=2;FontColor=0;")
    expect(described_class.new(root).width_for("EAID_A")).to eq(2)
  end

  it "treats a zero width as the one-pixel cosmetic pen, as QEA does" do
    expect(described_class.new(root_with("BorderWidth=0;")).width_for("EAID_A")).to eq(1)
  end

  it "has no width for an element without BorderWidth or an unknown subject" do
    root = root_with("BackColor=1;")
    borders = described_class.new(root)
    expect([borders.width_for("EAID_A"), borders.width_for("EAID_X")]).to eq([nil, nil])
  end
end
