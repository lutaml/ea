# frozen_string_literal: true

module Ea
  # ShapeScript interpreter namespace.
  #
  # EA's MDG technologies define stereotype icon decorations via a
  # domain-specific language called ShapeScript. This is a basic
  # interpreter supporting the core shape primitives:
  #
  #   shape <Name> { ... }
  #   rectangle(left, top, right, bottom);
  #   ellipse(left, top, right, bottom);
  #   polygon(x1, y1, x2, y2, ..., xN, yN);
  #   line(x1, y1, x2, y2);
  #   path(x1, y1, x2, y2, ...);
  #
  # Compound features (conditionals, variables, color references)
  # are out of scope for this basic interpreter.
  module Shapescript
    autoload :Parser, "ea/shapescript/parser"
    autoload :Renderer, "ea/shapescript/renderer"
    autoload :Shape, "ea/shapescript/shape"
  end
end
