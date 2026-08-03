# frozen_string: true

require "lutaml/model"

module Ea
  module Mdg
    # lutaml-model classes for the EA MDG.Technology XML format.
    # These are the deserialization models — use `from_xml` on
    # MdgTechnology to parse an MDG.Technology file.
    module Xml
      autoload :Technology, "ea/mdg/xml/technology"
      autoload :Documentation, "ea/mdg/xml/documentation"
      autoload :UmlProfiles, "ea/mdg/xml/uml_profiles"
      autoload :UmlProfile, "ea/mdg/xml/uml_profile"
      autoload :Content, "ea/mdg/xml/content"
      autoload :Stereotypes, "ea/mdg/xml/stereotypes"
      autoload :Stereotype, "ea/mdg/xml/stereotype"
      autoload :TaggedValues, "ea/mdg/xml/tagged_values"
      autoload :Tag, "ea/mdg/xml/tag"
      autoload :AppliesTo, "ea/mdg/xml/applies_to"
      autoload :Apply, "ea/mdg/xml/apply"
    end
  end
end
