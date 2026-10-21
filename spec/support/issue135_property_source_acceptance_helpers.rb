# frozen_string_literal: true

require "nokogiri"
require "tempfile"

# Retained blocks from examples/xmi/20251010_current_plateau_v5.1.xmi are byte-identical.
# Original SHA256: 695e16dda5c749a01e52a5630f1aa9c51744ba7bd47be4406ca0f104f64ba96c.
# Whole selected UMLDI/EA diagrams retain unresolved context references; no nodes are invented.
module Issue135PropertySourceAcceptanceHelpers
  CASES = {
    "lod0MultiCurve" => {
      fixture: "property-source-117-273-lod0MultiCurve.xmi", multiplicity: "0..1",
      diagram: "EAID_B53E76CD_A0F2_4e2f_B3AB_796D85964EF2",
      association: "EAID_69408358_DF5F_4031_B454_BA9B873976CF",
      property: "EAID_src408358_DF5F_4031_B454_BA9B873976CF",
      source: "EAID_B326682E_0384_443a_A119_96FD046071A2",
      target: "EAID_ACABD6DC_E4F2_4a04_BBD4_25CECBBDC6F6",
      bounds: { x: 629, y: 171, width: 76, height: 25 }, route: [[798, 217], [454, 213]],
      source_bounds: { x: 703, y: 177, width: 190, height: 80 },
      target_bounds: { x: 320, y: 20, width: 269, height: 387 },
      ports: [nil, nil], edges: [4, 4], llt: [62, -27, 98, 35], llb: [0, 0, 21, 18]
    },
    "opening" => {
      fixture: "property-source-146-629-opening.xmi", multiplicity: "0..*",
      diagram: "EAID_30D62231_110F_44e8_9C06_6FCDCBA53A09",
      association: "EAID_7C5F9D22_2C12_418b_B3A2_BCA11BAC2361",
      property: "EAID_src5F9D22_2C12_418b_B3A2_BCA11BAC2361",
      source: "EAID_31ADEE92_A536_4a6c_8CDB_F39FAFC392D4",
      target: "EAID_7FAA00A1_062E_4e51_8B1B_2B69DA559EC5",
      bounds: { x: 459, y: 1121, width: 49, height: 25 }, route: [[432, 1157], [970, 1158]],
      source_bounds: { x: 311, y: 1135, width: 120, height: 80 },
      target_bounds: { x: 971, y: 1024, width: 120, height: 161 },
      ports: [nil, nil], edges: [2, 2], llt: [24, -19, 57, 31], llb: [104, -31, 19, 16]
    },
    "extent" => {
      fixture: "property-source-25-139-extent.xmi", multiplicity: "0..1",
      diagram: "EAID_70C77F92_5614_4b22_8C8E_67859F59D8FD",
      association: "EAID_3CF59171_1DF6_43b6_AFC6_0339C04029FA",
      property: "EAID_srcF59171_1DF6_43b6_AFC6_0339C04029FA",
      source: "EAID_C9CBBBD8_47EB_447f_930C_22803660E549",
      target: "EAID_3EA549ED_B7DB_4947_939C_DD33689C7E42",
      bounds: { x: 718, y: 349, width: 49, height: 25 }, route: [[809, 402], [691, 402]],
      source_bounds: { x: 810, y: 380, width: 111, height: 70 },
      target_bounds: { x: 420, y: 380, width: 270, height: 71 },
      ports: [nil, nil], edges: [4, 4], llt: [2, -36, 66, 35], llb: [-17, 2, 21, 18]
    },
    "district" => {
      fixture: "property-source-54-892-district.xmi", multiplicity: "0..*",
      diagram: "EAID_2C8DD882_8DEA_4065_89F8_DDA796AA0C85",
      association: "EAID_96D760D5_57F4_4860_8A3B_6CD500FAA873",
      property: "EAID_srcD760D5_57F4_4860_8A3B_6CD500FAA873",
      source: "EAID_A8826BD2_3776_467e_B956_B64652029AD8",
      target: "EAID_331E7FB3_1C91_4c86_8ADD_49AA4ECD32A0",
      bounds: { x: 975, y: 1585, width: 49, height: 25 }, route: [[946, 1629], [1076, 1629], [1076, 1186]],
      source_bounds: { x: 570, y: 1569, width: 375, height: 394 },
      target_bounds: { x: 820, y: 1046, width: 390, height: 139 },
      ports: [nil, nil], edges: [2, 2], llt: [26, -27, 57, 31], llb: [93, -45, 19, 16]
    },
    "target" => {
      fixture: "property-source-89-889-target.xmi", multiplicity: "0..*",
      diagram: "EAID_BDA613D8_402A_475a_AA15_683D88FD3D23",
      association: "EAID_44332842_B1F3_493b_82B5_C2B79E5233A3",
      property: "EAID_src332842_B1F3_493b_82B5_C2B79E5233A3",
      source: "EAID_60CE61DE_7E88_4e8b_BFED_13500E7DCDEC",
      target: "EAID_ACABD6DC_E4F2_4a04_BBD4_25CECBBDC6F6",
      bounds: { x: 585, y: 203, width: 49, height: 25 }, route: [[519, 189], [562, 717]],
      source_bounds: { x: 274, y: 47, width: 330, height: 142 },
      target_bounds: { x: 296, y: 252, width: 287, height: 465 },
      ports: [[519, 189], [562, 717]], edges: [3, 3], llt: [163, 8, 66, 35], llb: [-42, 16, 19, 18]
    }
  }.freeze

  IDENTITY_CHANGES = {
    "wrong association" => lambda do |xml, data|
      xml.at_xpath("//*[@xmi:id='#{data[:property]}']")["association"] = "unrelated"
    end,
    "missing memberEnd" => lambda do |xml, data|
      xml.xpath("//*[local-name()='memberEnd'][@xmi:idref='#{data[:property]}']").remove
    end,
    "wrong memberEnd" => lambda do |xml, data|
      xml.at_xpath("//*[local-name()='memberEnd'][@xmi:idref='#{data[:property]}']")["xmi:idref"] = "unrelated"
    end,
    "duplicate edge" => lambda do |xml, data|
      edge = xml.at_xpath("//*[@modelElement='#{data[:association]}'][@source]")
      edge.add_next_sibling(edge.dup)
    end
  }.freeze

  def property_source_xml(data)
    Nokogiri::XML(File.read(fixtures_path("issue135_route_style/#{data[:fixture]}")))
  end

  def property_source_document(xml)
    Tempfile.create(["property-source", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end

  def property_source_bounds(diagram, element_ref)
    bounds = diagram.elements.find { |element| element.id == element_ref }.bounds
    { x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height }
  end

  def property_source_route(connector)
    connector.waypoints.map { |point| [point.position.x, point.position.y] }
  end

  def property_source_ports(connector)
    [connector.source_port, connector.target_port].map { |point| point && [point.x, point.y] }
  end

  def property_source_box(connector, key)
    connector.label_boxes.fetch(key).values_at("ox", "oy", "cx", "cy")
  end
end
