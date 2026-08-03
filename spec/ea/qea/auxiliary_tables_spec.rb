# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Ea::Qea auxiliary table coverage" do
  let(:db) { Ea.parse("examples/qea/basic.qea") }
  let(:plateau_db) { Ea.parse("examples/qea/20251010_current_plateau_v5.1.qea") }

  describe "t_operationparams" do
    it "loads rows with typed fields" do
      params = db.collections[:operation_params]
      expect(params.size).to eq(12)

      first = params.first
      expect(first).to be_a(Ea::Qea::Models::EaOperationParam)
      expect(first.name).not_to be_nil
      expect(first.kind).to eq("in")
      expect(first.input?).to be(true)
    end

    it "exposes parameters grouped by operation id" do
      any_op_id = db.collections[:operation_params].first.operationid
      params = db.operation_params_for(any_op_id)
      expect(params).not_to be_empty
      expect(params.first.operationid).to eq(any_op_id)
    end
  end

  describe "t_objectproperties" do
    it "loads rows from plateau v5.1" do
      props = plateau_db.collections[:object_properties]
      expect(props.size).to eq(1537)

      sample = props.find { |p| p.property == "isCollection" }
      expect(sample.value).to eq("false")
      expect(sample.boolean?).to be(true)
      expect(sample.boolean_value).to be(false)
    end

    it "exposes properties grouped by object id" do
      any_obj_id = plateau_db.collections[:object_properties].first.ea_object_id
      props = plateau_db.properties_for_object(any_obj_id)
      expect(props).not_to be_empty
    end
  end

  describe "t_objectconstraint" do
    it "loads rows from plateau v5.1" do
      constraints = plateau_db.collections[:object_constraints]
      expect(constraints.size).to eq(4)
      expect(constraints.first).to be_a(Ea::Qea::Models::EaObjectConstraint)
    end

    it "exposes constraints grouped by object id" do
      any_obj = plateau_db.collections[:object_constraints].first
      constraints = plateau_db.constraints_for_object(any_obj.ea_object_id)
      expect(constraints).not_to be_empty
    end
  end
end
