# frozen_string_literal: true

module CarlitoGdiSpecHelpers
  def carlito(text, **opts)
    Ea::Fonts::Metrics.text_length(text, 9, family: "Carlito", **opts)
  end
end
