# frozen_string_literal: true

require "nokogiri"

# Canonicalizes SVG XML for structural comparison. Strips whitespace,
# sorts attributes, ignores presentation-only attributes (shape-rendering,
# transform). Used by the visual regression spec.
module SvgCanonicalizer
  module_function

  def canonicalize(svg_string)
    doc = Nokogiri::XML(svg_string, &:noblanks)
    canonicalize_node(doc.root)
  end

  def canonicalize_node(node)
    return node.text.strip if node.text?
    return "" unless node.element?

    attrs = sorted_attrs(node)
    children = node.children.map { |c| canonicalize_node(c) }.reject(&:empty?)
    if children.empty?
      open_tag(node.name, attrs)
    else
      open_tag(node.name, attrs) + ":" + children.join(" ") + ">"
    end
  end

  def sorted_attrs(node)
    node.attributes
        .reject { |name, _| ignore_attribute?(name) }
        .sort_by(&:first)
        .map { |name, attr| "#{name}=\"#{attr.value}\"" }
  end

  def open_tag(name, attrs)
    if attrs.empty?
      "<#{name}>"
    else
      "<#{name} #{attrs.join(' ')}>"
    end
  end

  def ignore_attribute?(name)
    %w[shape-rendering transform].include?(name)
  end
end
