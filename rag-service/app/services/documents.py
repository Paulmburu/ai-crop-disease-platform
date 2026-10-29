"""Load the markdown knowledge base and split it into chunks.

Each note in knowledge/ starts with a small front-matter block:

    ---
    class_name: Tomato_Late_blight          # same label the Phase 1 classifier outputs
    plant: Tomato
    condition: Late blight
    sources: https://a.example | https://b.example
    ---
    # Tomato late blight
    ## Symptoms
    ...

Chunking strategy: split on "## " headings first (a section is one topic,
e.g. "Symptoms"), then split long sections into overlapping windows. Every chunk
is prefixed with its note title and section heading, so a chunk still makes
sense when retrieved on its own.
"""

import hashlib
from dataclasses import dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class Note:
    path: Path
    title: str
    body: str
    meta: dict[str, str] = field(default_factory=dict)


@dataclass(frozen=True)
class Chunk:
    id: str
    text: str
    meta: dict[str, str]


def parse_note(path: Path) -> Note:
    """Read one markdown note with an optional `---` front-matter block."""
    raw = path.read_text(encoding="utf-8")
    meta: dict[str, str] = {}
    if raw.startswith("---\n"):
        header, _, raw = raw[4:].partition("\n---\n")
        for line in header.splitlines():
            key, sep, value = line.partition(":")
            if sep:
                meta[key.strip()] = value.strip()
    lines = raw.strip().splitlines()
    title = lines[0].lstrip("# ").strip() if lines and lines[0].startswith("# ") else path.stem
    return Note(path=path, title=title, body="\n".join(lines[1:]).strip(), meta=meta)


def load_notes(knowledge_dir: Path) -> list[Note]:
    """Every *.md file except README.md, sorted for stable ids."""
    if not knowledge_dir.is_dir():
        raise FileNotFoundError(f"Knowledge folder not found: {knowledge_dir}")
    return [parse_note(p) for p in sorted(knowledge_dir.glob("*.md")) if p.name.lower() != "readme.md"]


def split_text(text: str, size: int, overlap: int) -> list[str]:
    """Split into windows of at most `size` chars, preferring paragraph/sentence/word breaks."""
    text = text.strip()
    if len(text) <= size:
        return [text] if text else []
    pieces, start = [], 0
    while start < len(text):
        end = min(start + size, len(text))
        if end < len(text):
            window = text[start:end]
            cut = max(window.rfind(sep) for sep in ("\n\n", "\n", ". ", " "))
            if cut > size // 2:  # only break early if it doesn't make the chunk tiny
                end = start + cut + 1
        pieces.append(text[start:end].strip())
        if end >= len(text):
            break
        start = max(end - overlap, start + 1)
    return [p for p in pieces if p]


def chunk_note(note: Note, size: int = 800, overlap: int = 100) -> list[Chunk]:
    """Turn one note into retrieval chunks with metadata and stable ids."""
    sections: list[tuple[str, str]] = []
    heading, buf = "Overview", []
    for line in note.body.splitlines():
        if line.startswith("## "):
            if any(s.strip() for s in buf):
                sections.append((heading, "\n".join(buf)))
            heading, buf = line[3:].strip(), []
        else:
            buf.append(line)
    if any(s.strip() for s in buf):
        sections.append((heading, "\n".join(buf)))

    chunks = []
    for heading, text in sections:
        for i, piece in enumerate(split_text(text, size, overlap)):
            body = f"{note.title} - {heading}\n{piece}"
            # Same file + section + position + content => same id, so re-ingesting never duplicates.
            digest = hashlib.sha1(f"{note.path.name}|{heading}|{i}|{body}".encode()).hexdigest()[:16]
            meta = {"source": note.path.name, "title": note.title, "section": heading,
                    **{k: note.meta[k] for k in ("class_name", "plant", "condition", "sources") if k in note.meta}}
            chunks.append(Chunk(id=digest, text=body, meta=meta))
    return chunks


def build_chunks(knowledge_dir: Path, size: int = 800, overlap: int = 100) -> list[Chunk]:
    return [c for note in load_notes(knowledge_dir) for c in chunk_note(note, size, overlap)]
