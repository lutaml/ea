# frozen_string_literal: true

require "nokogiri"

module NoteCjkWrapHelpers
  PLATEAU = "examples/qea/20251010_current_plateau_v5.1.qea"

  def plateau_document
    @plateau_document ||= Ea::Sources::Qea::Adapter.from_path(PLATEAU)
  end

  # [text, textLength] of the `count` emitted rows that start at the row
  # beginning with `first`.
  def note_rows(guid, first, count)
    nodes = qea_text_nodes(plateau_document, guid)
    start = nodes.index { |node| node.text.start_with?(first) }
    nodes[start, count].map { |node| [node.text, node["textLength"].to_i] }
  end
end
