# frozen_string_literal: true

module SourceSansProSpecHelpers
  def source_sans_pro_length(text, weight:, style: "normal")
    Ea::Fonts::Metrics.text_length(text, 7, family: "Source Sans Pro", weight: weight, style: style)
  end
end
