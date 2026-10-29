# Knowledge base

One markdown note per class the classifier predicts. The presentation demo uses the 3 potato
classes; notes for the other 12 PlantVillage classes are kept in `_other/` (not indexed).
Move a note back up one level and re-run ingest to include it.
`class_name` in each note's front matter matches the classifier's label exactly, so the
RAG service can restrict retrieval to the disease the image model found.

**These are learning notes, not agronomic advice.** They summarise the public extension
sources listed in each note's `sources:` field (UC IPM, NC State Extension, Pacific Pests,
Pathogens & Weeds). For real treatment decisions, consult your local extension service and
always follow pesticide labels and local regulations.

## Format

```markdown
---
class_name: Tomato_Late_blight
plant: Tomato
condition: Late blight
sources: https://... | https://...
---
# Title

## Section heading      <- each section becomes one or more retrieval chunks
Text...
```

Add or edit notes, then run `uv run python -m scripts.ingest` (or `POST /api/v1/index`).
