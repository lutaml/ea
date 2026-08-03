# frozen_string: true

require "spec_helper"

# Consolidated spec for the 13 QEA models added in earlier sessions
# (TODO.complete/44). Each model gets a primary-key check + a
# column-map check; the load-from-DB behavior is already exercised
# by spec/ea/qea/auxiliary_tables_extra_spec.rb.
RSpec.describe "Ea::Qea auxiliary models (primary key + column map)" do
  MODELS = [
    [Ea::Qea::Models::EaSecrypt, "t_secrypt", :secrypt_id,
     { "SecryptID" => :secrypt_id, "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaPalette, "t_palette", :palette_id,
     { "PaletteID" => :palette_id }],
    [Ea::Qea::Models::EaPaletteItem, "t_paletteitem", :palette_id,
     { "PaletteID" => :palette_id, "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaImplement, "t_implement", :implement_id,
     { "ImplementID" => :implement_id, "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaRoleConstraint, "t_roleconstraint",
     :roleconstraint_id,
     { "RoleConstraintID" => :roleconstraint_id,
       "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectProblem, "t_objectproblems",
     :object_problem_id,
     { "ObjectProblemID" => :object_problem_id,
       "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectRisk, "t_objectrisks", :object_risk_id,
     { "ObjectRiskID" => :object_risk_id, "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectTest, "t_objecttests", :object_test_id,
     { "ObjectTestID" => :object_test_id, "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectEffort, "t_objecteffort",
     :object_effort_id,
     { "ObjectEffortID" => :object_effort_id,
       "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectResource, "t_objectresource",
     :object_resource_id,
     { "ObjectResourceID" => :object_resource_id,
       "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectScenario, "t_objectscenarios",
     :object_scenario_id,
     { "ObjectScenarioID" => :object_scenario_id,
       "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectRequire, "t_objectrequires",
     :object_require_id,
     { "ObjectReqID" => :object_require_id,
       "Object_ID" => :ea_object_id }],
    [Ea::Qea::Models::EaObjectTrx, "t_objecttrx", :object_trx_id,
     { "ObjectTrxID" => :object_trx_id, "Object_ID" => :ea_object_id }]
  ].freeze

  it "covers 13 models" do
    expect(MODELS.size).to eq(13)
  end

  MODELS.each do |model_class, table_name, pk, column_map|
    describe model_class.name do
      it "declares the correct table_name" do
        expect(model_class.table_name).to eq(table_name)
      end

      it "declares the correct primary_key_column" do
        expect(model_class.primary_key_column).to eq(pk)
      end

      it "declares a column_map that translates Object_ID (when present)" do
        # Palettes don't reference an object; skip the Object_ID
        # check for them.
        next if model_class == Ea::Qea::Models::EaPalette

        expect(model_class.column_map["Object_ID"]).to eq(:ea_object_id)
      end

      it "declares the expected column_map entries" do
        column_map.each do |k, v|
          expect(model_class.column_map[k]).to eq(v),
            "expected #{model_class}.column_map[#{k.inspect}] = #{v.inspect}"
        end
      end

      it "builds an instance from a row hash" do
        # Construct a row from the column_map. Replace :ea_object_id
        # with a placeholder so lutaml-model accepts it.
        row = column_map.transform_values do |val|
          val == :ea_object_id ? 42 : 1
        end
        instance = model_class.from_db_row(row)
        expect(instance).to be_a(model_class)
        # Primary key types vary (string for PaletteID, integer
        # for the rest). Just verify the value is set.
        pk_value = instance.public_send(pk)
        expect(pk_value).not_to be_nil
      end
    end
  end
end
