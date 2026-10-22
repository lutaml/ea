# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Xmi::ExtensionTypes do
  let(:xml) do
    Nokogiri::XML(<<~XML)
      <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001">
        <xmi:Extension><elements><element>
          <attributes>
            <attribute idref="A1"><stereotype stereotype="voidable"/><properties type="Union"/></attribute>
            <attribute idref="A2"><properties type="Text"/></attribute>
          </attributes>
        </element></elements></xmi:Extension>
      </xmi:XMI>
    XML
  end

  subject(:types) { described_class.new(xml) }

  it "reads the stereotype EA stores on an attribute row" do
    expect(types.attribute_stereotype("A1")).to eq("voidable")
  end

  it "has none for a plain attribute and keeps the attribute type" do
    expect(types.attribute_stereotype("A2")).to be_nil
    expect(types.attribute_type("A2")).to eq("Text")
  end
end
