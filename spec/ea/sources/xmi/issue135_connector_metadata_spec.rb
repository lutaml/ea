# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connector saved endpoint and constraint metadata" do
  include Issue135ConnectorMetadataHelpers

  it "preserves both end stereotypes separately from the connector type and identity" do
    connector = metadata_connector(source: "property", target: "custom")

    expect(connector).to have_attributes(
      source_stereotype: "property", target_stereotype: "custom",
      relationship_ref: XmiConnectorEndHelpers::LINK_A,
      connector_type: "Association", direction: "Unspecified",
      is_substitutable: false
    )
    expect(connector.source_element_ref).not_to eq(connector.target_element_ref)
    expect(connector.waypoints).not_to be_empty
  end
end

RSpec.describe "XMI connector false substitutability annotation" do
  include Issue135ConnectorMetadataHelpers

  it "requests the native false annotation for the saved empty Boolean custom property" do
    connector = metadata_connector(value: "")

    expect(connector.is_substitutable).to be(true)
    expect(metadata_midpoint(connector)).to eq("{isSubstitutable=false}")
  end

  it "requests the false annotation for an explicit zero Boolean value" do
    expect(metadata_connector(value: "0").is_substitutable).to be(true)
  end

  it "does not request a false annotation for the explicit true Boolean value" do
    connector = metadata_connector(value: "-1")

    expect(connector.is_substitutable).to be(false)
    expect(metadata_midpoint(connector)).to be_nil
  end
end

RSpec.describe "XMI connector metadata preservation" do
  include Issue135ConnectorMetadataHelpers

  it "does not invent endpoint stereotypes or constraints when they are absent" do
    expect(metadata_connector).to have_attributes(
      source_stereotype: nil, target_stereotype: nil, is_substitutable: false
    )
  end
  it "ignores unrelated custom properties and differently scoped records without a source file" do
    unrelated = metadata_custom_property("0", name: "someOtherProperty")
    wrong_scope = metadata_custom_property("0").sub("connector property", "element property")

    [unrelated, wrong_scope, nil].each do |xrefs|
      expect(metadata_without_file(xrefs)).to eq(
        source_stereotype: nil, target_stereotype: nil, is_substitutable: false
      )
    end
  end
end
