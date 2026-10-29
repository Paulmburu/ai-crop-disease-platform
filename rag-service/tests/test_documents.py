from app.services.documents import build_chunks, chunk_note, load_notes, parse_note, split_text


def test_parse_note_reads_front_matter_and_title(knowledge_dir):
    note = parse_note(knowledge_dir / "tomato_late_blight.md")
    assert note.title == "Tomato late blight"
    assert note.meta["class_name"] == "Tomato_Late_blight"
    assert not note.body.startswith("---")


def test_readme_is_skipped(knowledge_dir):
    assert {n.path.name for n in load_notes(knowledge_dir)} == {"tomato_late_blight.md", "potato_early_blight.md"}


def test_chunks_follow_sections_and_carry_metadata(knowledge_dir):
    chunks = chunk_note(parse_note(knowledge_dir / "tomato_late_blight.md"))
    assert [c.meta["section"] for c in chunks] == ["Cause", "Management"]
    assert chunks[0].text.startswith("Tomato late blight - Cause\n")
    assert chunks[0].meta["class_name"] == "Tomato_Late_blight"


def test_chunk_ids_are_stable(knowledge_dir):
    assert [c.id for c in build_chunks(knowledge_dir)] == [c.id for c in build_chunks(knowledge_dir)]


def test_split_text_respects_size_and_overlaps():
    text = " ".join(f"word{i}" for i in range(400))
    parts = split_text(text, size=200, overlap=40)
    assert all(len(p) <= 200 for p in parts)
    assert len(parts) > 1
    assert parts[0][-20:].split()[-1] in parts[1]  # the window overlaps the previous one
    assert split_text("short", 200, 40) == ["short"]
    assert split_text("   ", 200, 40) == []
