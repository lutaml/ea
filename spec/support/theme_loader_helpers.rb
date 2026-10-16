# frozen_string_literal: true

require "tempfile"

module ThemeLoaderHelpers
  def loaded_theme(colors)
    file = Tempfile.new(["theme", ".yml"])
    file.write({ "id" => "plain", "name" => "Plain", "colors" => colors }.to_yaml)
    file.close
    Ea::Theme::Loader.load_file(file.path)
  ensure
    file&.unlink
  end
end
