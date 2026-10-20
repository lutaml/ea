# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Xmi::StoredRoute do
  include StoredRouteSideEntryHelpers

  it "preserves LH authored side-entry level for source-owned Bridge and Tunnel routes" do
    expect(stored_side_entry_route(source: [1191, 241, 202, 105], target: [611, 64, 330, 122], bend: [1292, 125]))
      .to eq([[1292, 241], [1292, 125], [941, 125]])
    expect(stored_side_entry_route(source: [957, 186, 202, 122], target: [611, 64, 330, 122], bend: [1058, 125]))
      .to eq([[1058, 186], [1058, 125], [941, 125]])
    expect(stored_side_entry_route(source: [920, 231, 202, 101], target: [530, 100, 330, 122], bend: [1021, 161]))
      .to eq([[1021, 231], [1021, 161], [860, 161]])
  end

  it "keeps parent-above redocking for non-LH routes" do
    expect(stored_side_entry_route(source: [1191, 241, 202, 105], target: [611, 64, 330, 122], bend: [1292, 125],
                                   style: "Mode=3;TREE=RH;LWidth=2;"))
      .to eq([[1292, 241], [1292, 125], [941, 186]])
  end
end
