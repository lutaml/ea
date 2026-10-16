# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Theme::Loader do
  include ThemeLoaderHelpers

  it "falls back to the theme text color when no attribute color is declared" do
    expect(loaded_theme("text" => "#101010").attribute_text_color).to eq("#101010")
  end

  it "keeps an attribute color the theme declares" do
    expect(loaded_theme("text" => "#101010", "attribute_text" => "#202020").attribute_text_color).to eq("#202020")
  end
end
