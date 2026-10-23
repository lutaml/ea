# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

# EA never repeats these nodes; hand-edited files must still load and not
# double-count constraints.
RSpec.describe "XMI extension with repeated nodes" do
  let(:basic) { File.read(File.expand_path("../../../fixtures/basic.xmi", __dir__)) }

  def write(dir, text)
    path = File.join(dir, "edited.xmi")
    File.write(path, text)
    path
  end

  describe Ea::Sources::Xmi::ConstraintBuilder do
    let(:xmi) do
      <<~XML
        <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001"><xmi:Extension><elements>
          <element xmi:idref="X"><constraints><constraint name="a" type="OCL"/></constraints>
            <constraints><constraint name="a" type="OCL"/></constraints></element>
          <element xmi:idref="X"><constraints><constraint name="a" type="OCL"/></constraints></element>
          <element xmi:idref="Y"><constraints><constraint name="b" type="OCL"/><constraint name="c" type="OCL"/></constraints></element>
        </elements></xmi:Extension></xmi:XMI>
      XML
    end

    it "reads each owner's first constraints block once" do
      Dir.mktmpdir do |dir|
        grouped = described_class.new(write(dir, xmi)).grouped_by_element

        expect(grouped.transform_values { |list| list.map(&:name) }).to eq("X" => ["a"], "Y" => %w[b c])
      end
    end
  end

  describe "a connector with a repeated <target>, <source> or <properties>" do
    %w[source target properties].each do |node|
      it "loads when <#{node}> is repeated" do
        text = basic.sub(%r{(<connector xmi:idref=[^>]*>.*?)(<#{node}\b[^>]*/>|<#{node}\b.*?</#{node}>)}m, '\1\2\2')
        expect(text).not_to eq(basic)

        Dir.mktmpdir do |dir|
          document = Ea::Sources::Xmi::Adapter.from_path(write(dir, text))

          expect(document.relationships).not_to be_empty
        end
      end
    end
  end
end
