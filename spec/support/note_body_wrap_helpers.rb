# frozen_string_literal: true

module NoteBodyWrapHelpers
  def wrap_note(text, width, size, family)
    Ea::Svg::EaEmitter::Compartment::NoteBody.wrap_paragraph(text, width - 4, size, family)
  end
end
