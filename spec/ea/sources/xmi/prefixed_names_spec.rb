# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Sparx XMI classifiers named with a namespace prefix" do
  let(:document) do
    Ea::Sources::Xmi::Adapter.from_path(fixtures_path("prefixed_names.xmi"))
  end
  let(:classifiers) { document.classifiers.to_h { |c| [c.name, c] } }

  it "keeps the saved name as the qualified name" do
    expect(classifiers["gml:CodeType"].qualified_name).to eq("gml:CodeType")
  end

  it "keeps the saved name on attribute types" do
    code_value = classifiers["Zone"].properties.first

    expect(code_value.type_name).to eq("gml:CodeType")
  end

  it "still qualifies unprefixed names with the package" do
    expect(classifiers["Zone"].qualified_name).to eq("urf::Zone")
  end
end

RSpec.describe "Sparx XMI foreign package headers" do
  include PrefixedNameHeaderHelpers

  let(:document) do
    Ea::Sources::Xmi::Adapter.from_path(fixtures_path("prefixed_names.xmi"))
  end

  it "prefixes a classifier owned by another package on a HighlightForeign diagram" do
    expect(rendered_texts(document, "ForeignView")).to include("urf::Zone")
  end

  it "leaves a classifier unprefixed on its own package's diagram" do
    texts = rendered_texts(document, "OwnView")

    expect(texts).to include("Zone")
    expect(texts).not_to include("urf::Zone")
  end

  it "shows a gml-typed attribute as saved" do
    texts = rendered_texts(document, "OwnView")

    expect(texts).to include("codeValue: gml:CodeType")
  end
end
