# frozen_string_literal: true

require "spec_helper"

# Issue #278: the QEA lazy drop path must produce the same drop
# content as the XMI path for the same model — that equivalence is
# what lets klass-table templates consume .qea sources without the
# XMI materialization.
RSpec.describe Ea::Qea::LazyDrops do
  let(:qea_path) { File.expand_path("../../../examples/qea/basic.qea", __dir__) }
  let(:database) { Ea::Qea.load(qea_path) }

  after { database&.close_connection }

  def xmi_root_drop
    xml = Ea::Transformers.qea_to_xmi(database)
    Ea::Xmi::Parser.new.serialize_to_liquid(Xmi::Sparx::Root.parse_xml(xml))
  end

  def xmi_class_drops
    xmi_root_drop.packages.flat_map do |package|
      package.classes.map { |klass| [klass.name, klass] }
    end.to_h
  end

  def qea_class_drops
    context = described_class.for(database)
    context.class_object_ids.filter_map do |object_id|
      klass = context.klass_for(object_id)
      next unless klass

      drop = Ea::Xmi::LiquidDrops::KlassDrop.new(klass, nil, context.drop_options)
      [klass.xmi_id, drop]
    end.to_h
  end

  def whole_class_drops
    whole = {}
    walk = lambda do |packages|
      packages.each do |package|
        package.classes&.each { |klass| whole[klass.xmi_id] = klass }
        walk.call(package.packages)
      end
    end
    walk.call(Ea.to_uml(database).packages)
    whole
  end

  def klass_summary(drop)
    {
      attributes: drop.attributes.map do |attr|
        [attr.name, attr.type.to_s]
      end.sort,
      operations: drop.operations.map(&:name).sort
    }
  end

  it "builds classes lazily from the database rows" do
    context = described_class.for(database)
    ids = context.class_object_ids
    expect(ids).not_to be_empty

    built = ids.filter_map { |id| context.klass_for(id) }
    expect(built.all?(Lutaml::Uml::UmlClass)).to be(true)
    expect(built.map(&:name).uniq.sort)
      .to eq(database.objects.all.select(&:uml_class?).map(&:name).uniq.sort)
  end

  it "caches repeated construction per xmi id" do
    context = described_class.for(database)
    id = context.class_object_ids.first

    first = context.klass_for(id)
    second = context.klass_for(id)
    expect(first).to equal(second)
  end

  it "answers the lookup surface the drops consume" do
    context = described_class.for(database)
    lookup = context.lookup

    object = database.objects.all.find { |o| o.name && o.ea_guid }
    xmi_id = context.object_xmi_id(object)
    expect(lookup.lookup_entity_name(xmi_id)).to eq(object.name)
    expect(lookup.id_name_mapping).to include(xmi_id => object.name)
    expect(lookup.doc_node_attribute_value(xmi_id, "stereotype")).to eq(object.stereotype)
    expect(lookup.find_matched_element(xmi_id)).to be_nil
    expect(context.drop_options[:lookup]).to be(context.lookup)
  end

  it "matches the whole-document factory output per class" do
    require "lutaml/uml"

    lazy = qea_class_drops
    whole = whole_class_drops

    shared = lazy.keys & whole.keys
    expect(shared).not_to be_empty

    shared.each do |xmi_id|
      context = described_class.for(database)
      lazy_drop = lazy[xmi_id]
      whole_drop = Ea::Xmi::LiquidDrops::KlassDrop.new(whole[xmi_id], nil,
                                                       context.drop_options)
      expect(klass_summary(lazy_drop)).to eq(klass_summary(whole_drop)),
                                          "class #{xmi_id} diverges between the lazy and whole-document paths"
    end
  end

  it "carries the database ground truth for one known class" do
    lazy = qea_class_drops
    named = lazy.values.find do |drop|
      drop.attributes.any? { |attr| attr.name && !attr.name.empty? }
    end
    expect(named).not_to be_nil
    named.attributes.each do |attr|
      row = database.attributes.find { |a| a.name == attr.name }
      expect(row).not_to be_nil,
                         "attribute #{attr.name} exists in the rendered class but not in t_attribute"
    end
  end
end

RSpec.describe "Ea::Qea::LazyDrops plugin contract" do
  let(:qea_path) { File.expand_path("../../../examples/qea/basic.qea", __dir__) }

  it "serves the parsed-source shape the klass-table cache consumes" do
    parsed = Ea::Qea::LazyDrops.parsed(qea_path)

    expect(parsed.parser.xmi_root_model.model.name).to eq("EA Model")

    klass_record = parsed.parser.xmi_index
                         .find_packaged_by_name_and_types(
                           "Class A", ["uml:Class"]
                         )
    expect(klass_record).not_to be_nil
    expect(klass_record.name).to eq("Class A")

    built = parsed.xmi_id_index[klass_record.id]
    expect(built).to be_a(Lutaml::Uml::UmlClass)
    expect(built.name).to eq("Class A")

    enums = parsed.parser.xmi_index.packaged_elements_of_type("uml:Enumeration")
    enums.each do |record|
      expect(parsed.xmi_id_index[record.id]).to be_a(Lutaml::Uml::Enum)
    end
  end

  it "walks parent packages through the index shim" do
    parsed = Ea::Qea::LazyDrops.parsed(qea_path)
    index = parsed.parser.xmi_index

    record = index.packaged_elements_of_type("uml:Class").first
    parent = index.find_parent(record.id)
    expect(parent).not_to be_nil
    expect(parent.name).not_to be_empty
  end
end
