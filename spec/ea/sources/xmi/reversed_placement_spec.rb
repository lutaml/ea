# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

# Edits connector 3B1A629A of basic.xmi diagram 14E9F5FD (start 81153377 with
# DUID 0256031A, end E4C85654 with DUID E95D999F) to carry a one-corner Path.
RSpec.describe Ea::Sources::Xmi::DiagramBuilder, "reversed placement detection" do
  let(:link_line) { /^(.*subject="EAID_3B1A629A[^\n]*)$/ }
  let(:corner_path) { "Path=330:-300$;" }

  def corner_route(ids)
    Dir.mktmpdir do |dir|
      xmi = File.read("spec/fixtures/basic.xmi")
      xmi = xmi.sub(link_line) { |line| line.sub("Path=;", corner_path).sub(/EOID=\w+;SOID=\w+/, ids) }
      path = File.join(dir, "edit.xmi")
      File.write(path, xmi)
      diagram = described_class_adapter.from_path(path).diagrams.find { |d| d.id.include?("14E9F5FD") }
      connector = diagram.connectors.find { |c| c.relationship_ref.include?("3B1A629A") }
      connector.waypoints.map { |point| [point.position.x, point.position.y] }
    end
  end

  def described_class_adapter
    Ea::Sources::Xmi::Adapter
  end

  it "does not treat a stale SOID as reversed" do
    expect(corner_route("EOID=BD96ECCB;SOID=9A6B6F88")).to eq([[268, 120], [377, 120], [377, 156]])
  end

  it "does not treat one resolvable and one stale end as reversed" do
    expect(corner_route("EOID=BD96ECCB;SOID=E95D999F")).not_to include([330, 300])
  end

  it "routes a crossed, resolvable SOID/EOID pair as a reversed corner" do
    expect(corner_route("EOID=0256031A;SOID=E95D999F")).to eq([[231, 195], [330, 300], [377, 174]])
  end

  it "keeps the uncrossed resolvable pair on the normal route" do
    expect(corner_route("EOID=E95D999F;SOID=0256031A")).to eq([[268, 120], [377, 120], [377, 156]])
  end
end
