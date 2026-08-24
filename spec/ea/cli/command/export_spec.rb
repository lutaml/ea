# frozen_string_literal: true

require "spec_helper"
require "ea/cli"
require "tmpdir"

RSpec.describe Ea::Cli::Command::Export do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:output_path) { File.join(Dir.mktmpdir, "out.xmi") }

  after { FileUtils.rm_rf(File.dirname(output_path)) }

  it "emits MDG stereotype definitions when --mdg is given" do
    capture_stdout do
      described_class.new(
        sub: "xmi", file: qea_path, output: output_path,
        mdg: [fixtures_path("mdg/CityGML_MDG_Technology.xml")]
      ).call
    end
    xml = File.read(output_path)
    expect(xml).to include("uml:Stereotype")
    expect(xml).to include(%(memberEnd="extension_))
    expect(xml).not_to include(%(<memberEnd xmi:idref="extension_))
  end

  it "emits no stereotype definitions without --mdg" do
    capture_stdout do
      described_class.new(sub: "xmi", file: qea_path, output: output_path).call
    end
    expect(File.read(output_path)).not_to include("uml:Stereotype")
  end

  it "ignores --mdg for non-xmi formats" do
    json_path = output_path.sub(".xmi", ".json")
    capture_stdout do
      described_class.new(
        sub: "json", file: qea_path, output: json_path,
        mdg: [fixtures_path("mdg/CityGML_MDG_Technology.xml")]
      ).call
    end
    expect(JSON.parse(File.read(json_path))).to be_a(Hash)
  end
end
