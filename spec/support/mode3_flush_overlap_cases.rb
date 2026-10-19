# frozen_string_literal: true

module Mode3FlushOverlapCases
  # Native Basic diagrams 13, 14, 15, 16 and 18; rendered fixture paths include its canvas translation.
  NATIVE_CASES = [
    [[100, 100, 117, 71], [399, 100, 117, 71], 137, "M 152 77 L 334 77"],
    [[100, 100, 115, 70], [399, 100, 115, 70], 137, "M 150 77 L 334 77"],
    [[100, 100, 134, 70], [420, 100, 134, 70], 137, "M 169 77 L 355 77"],
    [[100, 100, 125, 70], [420, 100, 125, 70], 137, "M 160 77 L 355 77"],
    [[100, 100, 136, 101], [420, 100, 136, 101], 152, "M 171 92 L 355 92"]
  ].freeze

  CONTROLS = [
    [{ style: "Mode=3;LWidth=1;" }, "M 35 97 L 355 97 L 355 77"],
    [{ geometry: "SX=-6;SY=-2;EX=-57;EY=-2;EDGE=1;" }, "M 169 77 L 355 77"],
    [{ geometry: "SX=-6;SY=-2;EX=-57;EY=1;EDGE=2;" }, "M 169 76 L 355 74"],
    [{ style: "Mode=3;LWidth=2;" }, "M 170 77 L 354 77"],
    [{ style: "Mode=3;LWidth=0;TREE=V;" }, "M 35 97 L 355 97 L 355 77"],
    [{ path: "300:-200;" }, "M 35 97 L 355 97 L 355 77"],
    [{ geometry: "SX=-6;SY=-2;EX=-57;EY=-2;EDGE=4;" }, "M 169 77 L 355 77"],
    [{ source: [420, 100, 134, 70], target: [100, 100, 134, 70] }, "M 355 77 L 169 77"],
    [{ target: [420, 300, 134, 70] }, "M 140 110 L 355 269"]
  ].freeze

  def flush_overlap_points(document)
    diagram = document.diagrams.first
    labels = Ea::Svg::EaEmitter::Labels.new(diagram, model_index: document.index_by_id, document: document)
    labels.send(:label_points, diagram.connectors.first)
  end
end
