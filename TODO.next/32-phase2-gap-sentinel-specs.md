# 32 - Phase 2 gap sentinel specs (assert absent attributes)

## Status: DONE (2026-07-01)

## Problem
TODO 21 documents four attribute gaps the xmi gem doesn't yet model:
`visibility`, `isAbstract`, `classifier`, `aggregation`. These are
intentionally dropped in Phase 1 of the rewrite.

The current spec suite does not assert the *absence* of these
attributes. When the xmi gem adds support for them (small focused
PRs to lutaml/xmi), nothing in the ea test suite signals that we
should wire them up. The silent skip can persist for months.

## Fix
Add sentinel specs that explicitly assert these attributes are not
emitted today, with a comment pointing at TODO 21:

```ruby
describe "Phase 2 gaps (intentionally absent — see TODO.next/21)" do
  it "does not emit visibility on Property" do
    expect(parsed.xpath("//ownedAttribute[@visibility]")).to be_empty
  end

  it "does not emit isAbstract on packagedElement" do
    expect(parsed.xpath("//packagedElement[@isAbstract]")).to be_empty
  end

  it "does not emit aggregation on ownedEnd" do
    expect(parsed.xpath("//ownedEnd[@aggregation]")).to be_empty
  end

  it "does not emit classifier on InstanceSpecification" do
    expect(parsed.xpath("//packagedElement[@classifier]")).to be_empty
  end
end
```

When the xmi gem adds support, the first PR that wires the attribute
up will need to flip these to positive assertions — making the
wiring visible in code review.

## Verification
All four sentinels pass against current output (no `visibility`,
`isAbstract`, `aggregation`, `classifier` attributes emitted).
