# frozen_string_literal: true

require "spec_helper"
require "ea/cli/app"

RSpec.describe "ea svg CLI command" do
  let(:app) { Ea::Cli::App.new }
  let(:xmi_fixture) { fixtures_path("basic.xmi") }

  after { FileUtils.rm_f([@out].compact) }

  it "renders a named diagram to a standalone SVG file" do
    @out = "/tmp/ea_svg_command_spec.svg"
    capture_stdout do
      app.invoke(:svg, ["Starter Object Diagram", xmi_fixture], output: @out)
    end
    expect(File.exist?(@out)).to be(true)
    contents = File.read(@out)
    expect(contents).to start_with("<?xml")
    expect(contents).to include("<svg")
  end

  it "raises Ea::Cli::Error for an unknown diagram name" do
    expect {
      capture_stdout do
        app.invoke(:svg, ["Does Not Exist", xmi_fixture],
                   output: "/tmp/ea_svg_unknown.svg")
      end
    }.to raise_error(Ea::Cli::Error, /not found/)
  end
end
