# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Ea::Xmi::Slicer do
  # A class whose attribute references an EA built-in primitive type:
  # the primitives live in the extension's primitivetypes block under
  # EAJava_-prefixed ids, and the reference rides a plain <type
  # xmi:idref> inside the attribute. A slice of the referencing class
  # has to carry the primitive and its package wrappers, or the sliced
  # parse resolves the attribute's type to the raw idref where the
  # whole-load parse resolves the type name.
  let(:source) { fixtures_path("primitive_types_reference.xmi") }

  def building_measured_height_type(xml)
    parsed = Ea::Xmi.load_graph(StringIO.new(xml))
    raw = parsed.parser.xmi_index.find_packaged_by_name_and_types(
      "Building", ["uml:Class", "uml:AssociationClass"]
    )
    klass = parsed.xmi_id_index[raw.id]
    inherited = klass.generalization.inherited_props
                     .find { |a| a.name == "measuredHeight" }

    inherited.type
  end

  it "keeps a referenced primitive type in the slice" do
    xml = described_class.slice(source, [[nil, "Building"]])

    expect(xml).to include('xmi:id="EAJava_gml__LengthType"')
    # the writer cuts children of gated containers that the keep set
    # does not hold, so the presence of the wrapper package ids proves
    # the ancestry of the kept primitive survived
    expect(xml).to include("EAPrimitiveTypesPackage")
    expect(xml).to include("EAJavaTypesPackage")
  end

  it "does not keep unreferenced primitive types" do
    xml = described_class.slice(source, [[nil, "Building"]])

    expect(xml).not_to include("EAJava_xs__string")
  end

  it "resolves the sliced attribute's type to the primitive name" do
    xml = described_class.slice(source, [[nil, "Building"]])

    expect(building_measured_height_type(xml)).to eq("gml::LengthType")
  end

  it "resolves the type through a multi-group slice" do
    groups = { "building" => [[nil, "Building"]] }
    xml = described_class.slices(source, groups).fetch("building")

    expect(building_measured_height_type(xml)).to eq("gml::LengthType")
  end
end
