# frozen_string_literal: true

require "spec_helper"
require "ea/cli/app"

# Specs for the `ea spa` CLI command. Exercises both QEA and XMI
# inputs and asserts the command produces a real SPA HTML file.
RSpec.describe "ea spa CLI command" do
  let(:app) { Ea::Cli::App.new }

  after do
    FileUtils.rm_f([@qea_out, @xmi_out].compact)
  end

  def run_spa(file, output)
    capture_stdout do
      app.invoke(:spa, [file], output: output)
    end
  end

  it "generates a SPA from a QEA file" do
    @qea_out = "/tmp/ea_spa_qea_spec.html"
    run_spa(fixtures_path("basic.qea"), @qea_out)
    expect(File.exist?(@qea_out)).to be(true)
    expect(File.size(@qea_out)).to be > 50_000
  end

  it "generates a SPA from an XMI file" do
    @xmi_out = "/tmp/ea_spa_xmi_spec.html"
    run_spa(fixtures_path("basic.xmi"), @xmi_out)
    expect(File.exist?(@xmi_out)).to be(true)
    expect(File.size(@xmi_out)).to be > 10_000
  end

  it "the generated SPA contains an HTML root with a script element" do
    @xmi_out = "/tmp/ea_spa_vue_spec.html"
    run_spa(fixtures_path("basic.xmi"), @xmi_out)
    content = File.read(@xmi_out)
    expect(content).to match(/<html/i)
    expect(content).to match(/<script/i)
  end

  it "rejects an unsupported mode" do
    expect {
      capture_stdout do
        app.invoke(:spa, [fixtures_path("basic.qea")],
                   mode: "bogus", output: "/tmp/ea_spa_bogus.html")
      end
    }.to raise_error(Ea::Cli::UnsupportedFormat)
  end
end
