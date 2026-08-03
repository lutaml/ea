# TODO-D 77: basic.qea text over-render (+2)

## Status: open

basic.qea's two diagrams overshoot text by 1 each:

  - Classes: +1
  - Composition with Substitution: +1

## Composition with Substitution diff

  Ours has:
    +1 "Class B.3" (split qualified name part)
    +1 "Class B.2"
    +1 "Class B.1"
    +1 "«property»" (spurious property stereotype)

  Ref has:
    +1 "Class B::Class B.1" (single qualified name line)
    +1 "Class B::Class B.2"
    +1 "Class B::Class B.3"

So our qualified-name wrap is incorrectly splitting "Class B::X"
into two lines for these nested classes. The qualified name should
render as ONE line per element, not as "Class B::" + "X".

The spurious "«property»" text appears to come from a connector
SourceRole label that we render but ref doesn't on this diagram.

## Classes diff

Need to identify what specific text differs on the Classes diagram.

## Next step

1. Inspect why qualified-name wrap triggers for "Class B::Class B.X"
   (likely a width estimation mismatch).
2. Identify the connector whose SourceRole produces "«property»"
   and apply the right suppression (similar to aggregation arrow
   fix — only render on specific directions).
