# frozen_string_literal: true

module CjkFallbackHelpers
  def emitted_width(text, size, family, **font)
    Ea::Svg::EaEmitter::TextRenderer.estimate_width(text, size, family: family, **font).round
  end
end
