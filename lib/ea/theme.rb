# frozen_string_literal: true

module Ea
  # Ea::Theme is the domain-level concept of diagram visual themes.
  #
  # A Theme bundles the visual style settings that EA applies
  # uniformly across a diagram: font family, font size, text
  # color, border color, stroke width, and per-classifier-type
  # fill colors.
  #
  # Themes are looked up by ID from {Registry}. The ID comes from
  # the diagram's `t_diagram.StyleEx` field (e.g., `Theme=:119`).
  #
  # Built-in themes (loaded from `config/themes/*.yml`):
  #   :default — no overrides, uses element-stored values
  #   "119"    — Carlito 7pt, gray text, purple-gray borders
  #
  # Users can create custom themes:
  #
  #   custom = Ea::Theme::Definition.new(
  #     id: "custom", name: "My Theme",
  #     font_family: "Arial", font_size: 12,
  #     text_color: "#000000", border_color: "#333333",
  #     stroke_width: 1
  #   )
  #   diagram.theme = custom
  #
  # Or load from a YAML file:
  #
  #   Ea::Theme::Registry.load_dir("path/to/themes/")
  #
  module Theme
    autoload :Definition, "ea/theme/definition"
    autoload :Registry, "ea/theme/registry"
    autoload :Loader, "ea/theme/loader"
  end
end
