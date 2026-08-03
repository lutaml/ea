# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/attribute_line_builder"

RSpec.describe Ea::Svg::EaEmitter::Element::AttributeLineBuilder do
  let(:host) do
    Ea::Model::Klass.new(id: "HOST", name: "Host", package_id: "PKG_HOST",
                          package_name: "host_pkg")
  end

  let(:foreign_owner) do
    Ea::Model::Klass.new(id: "OWNER", name: "Owner", package_id: "PKG_OTHER",
                          package_name: "other_pkg")
  end

  let(:lookup) { lambda { |id| id == "OWNER" ? foreign_owner : nil } }

  def build_property(attrs = {})
    defaults = { name: "prop", visibility: "public" }
    Ea::Model::Property.new(defaults.merge(attrs))
  end

  describe "visibility marker" do
    it "uses + for public" do
      prop = build_property(visibility: "public")
      line = described_class.new(prop).to_s
      expect(line).to start_with("+ ")
    end

    it "uses - for private" do
      prop = build_property(visibility: "private")
      expect(described_class.new(prop).to_s).to start_with("- ")
    end

    it "uses # for protected" do
      prop = build_property(visibility: "protected")
      expect(described_class.new(prop).to_s).to start_with("# ")
    end

    it "uses ~ for package" do
      prop = build_property(visibility: "package")
      expect(described_class.new(prop).to_s).to start_with("~ ")
    end
  end

  describe "type name" do
    it "renders the type after the name with a colon" do
      prop = build_property(name: "age", type_name: "xs::integer")
      expect(described_class.new(prop).to_s).to include(": xs::integer")
    end

    it "omits the type section when type_name is empty" do
      prop = build_property(name: "anon", type_name: "")
      expect(described_class.new(prop).to_s).to eq("+ anon")
    end

    it "preserves the exact type_name string (no namespace rewriting)" do
      prop = build_property(name: "x", type_name: "xs:date")
      expect(described_class.new(prop).to_s).to include(": xs:date")
    end
  end

  describe "multiplicity" do
    it "is hidden when lower=1 and upper=1" do
      prop = build_property(name: "x", multiplicity_lower: 1, multiplicity_upper: 1)
      expect(described_class.new(prop).to_s).not_to include("[")
    end

    it "renders a range for asymmetric bounds" do
      prop = build_property(name: "x", multiplicity_lower: 0, multiplicity_upper: 1)
      expect(described_class.new(prop).to_s).to include("[0..1]")
    end

    it "renders * for unlimited upper" do
      prop = build_property(name: "x", multiplicity_lower: 0, multiplicity_upper: -1)
      expect(described_class.new(prop).to_s).to include("[0..*]")
    end
  end

  describe "default value" do
    it "appends = value when default_value is present" do
      prop = build_property(name: "color", default_value: "red")
      expect(described_class.new(prop).to_s).to include("= red")
    end
  end

  describe "namespace prefix on inherited properties" do
    it "is omitted when the property is owned by the host" do
      prop = build_property(name: "name", owner_id: "HOST")
      line = described_class.new(prop, host: host, lookup: lookup).to_s
      expect(line).to include("+ name")
      expect(line).not_to include("::")
    end

    it "is added when the property's owner is in a different package" do
      prop = build_property(name: "inherited", owner_id: "OWNER")
      line = described_class.new(prop, host: host, lookup: lookup).to_s
      expect(line).to include("+ other_pkg::inherited")
    end

    it "is omitted when no lookup is provided" do
      prop = build_property(name: "inherited", owner_id: "OWNER")
      line = described_class.new(prop, host: host).to_s
      expect(line).to include("+ inherited")
    end

    it "is omitted when owner classifier is missing from lookup" do
      prop = build_property(name: "orphan", owner_id: "MISSING")
      line = described_class.new(prop, host: host, lookup: lookup).to_s
      expect(line).to include("+ orphan")
    end

    it "is omitted when owner is in the same package as host" do
      same_pkg_owner = Ea::Model::Klass.new(id: "SIBLING", package_id: "PKG_HOST",
                                              package_name: "host_pkg")
      lookup = lambda { |id| id == "SIBLING" ? same_pkg_owner : nil }
      prop = build_property(name: "cousin", owner_id: "SIBLING")
      line = described_class.new(prop, host: host, lookup: lookup).to_s
      expect(line).to include("+ cousin")
    end
  end
end
