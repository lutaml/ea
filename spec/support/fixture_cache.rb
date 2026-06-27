# frozen_string_literal: true

module FixtureCache
  CACHE = {} # rubocop:disable Style/MutableConstant

  def cached_qea_database(path, **options)
    key = :"qea_db:#{path}:#{options.hash}"
    CACHE[key] ||= Ea::Qea::Services::DatabaseLoader
      .new(path, options[:config]).load
  end

  def cached_qea_parse(path, **options)
    key = :"qea:#{path}:#{options.hash}"
    CACHE[key] ||= Ea::Qea.parse(path, **options)
  end

  def cached_ea_to_uml_document(qea_path)
    key = :"ea_doc:#{qea_path}"
    CACHE[key] ||= begin
      db = cached_qea_database(qea_path)
      Ea::Qea::Factory::EaToUmlFactory.new(db).create_document
    end
  end
end

RSpec.configure do |config|
  config.include FixtureCache
end
