# frozen_string_literal: true

module XmiReceptionHelpers
  def reception_source_contracts
    [
      ["EAID_A33766B2_CB5E_4a70_B6CD_FA24D9462824", "EAID_5F2256D3_8EEE_4371_8413_83233BCAF0E5", "Signal A"],
      ["EAID_766DD930_0679_4761_83C1_E904741A6020", "EAID_BB1DC0B9_2A2D_45ec_A2A1_3114FE692291", "Signal C"],
      ["EAID_F1BAB98F_97BC_4461_BF93_63D51BF4DCA4", "EAID_4B9DB992_F034_40c4_9DC4_50ED2F453670", "Signal C"]
    ]
  end

  def reception_visibility_xml
    <<~XML
      <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
               xmlns:uml="http://www.omg.org/spec/UML/20161101">
        <uml:Model name="Model">
          <packagedElement xmi:type="uml:Class" xmi:id="MixedCase" name="Owner">
            <ownedReception name="Private signal" visibility="private"/>
            <ownedReception xmi:id="scoped" name="Scoped signal"/>
            <ownedReception xmi:id="defaulted" name="Default signal"/>
          </packagedElement>
        </uml:Model>
        <xmi:Extension>
          <element xmi:id="decoy"><ownedReception xmi:id="ignored"/></element>
          <receptions><reception xmi:idref="scoped" scope="Private"/></receptions>
        </xmi:Extension>
      </xmi:XMI>
    XML
  end
end
