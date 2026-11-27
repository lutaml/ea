# frozen_string_literal: true

require "moxml"

module NoteCjkWrapHelpers
  PLATEAU = "examples/qea/20251010_current_plateau_v5.1.qea"

  def plateau_document
    @plateau_document ||= Ea::Sources::Qea::Adapter.from_path(PLATEAU)
  end

  # [text, textLength] of the `count` emitted rows that start at the row
  # beginning with `first`.
  def note_rows(guid, first, count)
    nodes = qea_text_nodes(plateau_document, guid)
    start = nodes.to_a.index { |node| node.content.start_with?(first) }
    nodes.to_a[start, count].map { |node| [node.content, node["textLength"].to_i] }
  end
end
