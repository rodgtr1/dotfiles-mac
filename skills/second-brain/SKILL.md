---
name: second-brain
description: >
  Operate Travis's second brain wiki at ~/Repos/second-brain. Trigger when Travis
  says "second brain", "my wiki", "the wiki", "add this to my second brain",
  "ingest this", "ingest this into my wiki", "ingest this into the wiki",
  "save this to the wiki", "add this to the wiki", "put this in my wiki",
  "file this", "what does my wiki say about X", "what do I have on X",
  "query the wiki", "lint the wiki", "update my memory", or invokes /second-brain
  directly. This skill shifts context to the second brain repo and performs ingest,
  query, lint, or memory operations according to the schema in CLAUDE.md.
---

# Second Brain Skill

Travis has a personal knowledge base (second brain) at `~/Repos/second-brain`. When this skill is invoked, you are operating as the wiki maintainer for that repo.

## First: load context

Before doing anything else, read these files in order:

1. `~/Repos/second-brain/CLAUDE.md` — the full operating manual (structure, workflows, conventions)
2. `~/Repos/second-brain/index.md` — the content catalog (what pages exist)
3. The last 5 log entries from `~/Repos/second-brain/log.md` — recent activity

This gives you the full picture of what the wiki contains and what's been done recently.

## Determine the operation

Based on how /second-brain was invoked, determine what to do:

**Ingest** — Travis is sharing content (an article, a conversation, a note, a URL, or just pasted text) and wants it saved to the wiki. Follow the ingest workflow in CLAUDE.md exactly. Write to `~/Repos/second-brain/`.

**Query** — Travis is asking a question against the wiki ("what do I have on X", "summarize what I know about Y"). Read the index, pull relevant pages, synthesize an answer with citations. If the answer is valuable, file it as an analysis page.

**Lint** — Travis wants a health check. Read all wiki pages, find issues, write a report.

**Memory** — Travis wants to update `~/Repos/second-brain/Memory.md` (his personal context file). Update or create it with the information provided.

**No explicit operation** — ask Travis what he wants to do: ingest the content into the wiki, query something, or something else.

## After every operation

- Update `~/Repos/second-brain/index.md` if new pages were created
- Append to the TOP of `~/Repos/second-brain/log.md`
- Report every file touched

## Important

- All writes go to `~/Repos/second-brain/` — never to the current working project
- Never modify files in `~/Repos/second-brain/raw/` — those are immutable sources
- Follow the page format (YAML frontmatter) and slug conventions from CLAUDE.md
- Cross-link aggressively — a new page should link to existing pages where relevant
