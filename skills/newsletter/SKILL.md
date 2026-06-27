---
name: travis-newsletter
description: Generate a weekly Travis Media newsletter covering AI, programming, and tech news. Use this skill whenever Travis asks to write, draft, or research for his weekly newsletter, mentions "newsletter", asks for this week's tech/AI/programming roundup, wants to find an open source project to feature, needs a "try this in 5 minutes" section, or asks for poll/quiz ideas. Also trigger when Travis says things like "let's do this week's issue", "what's new in tech this week", "help me with the next edition", or "research for the newsletter". This skill uses web search to find current news and an open source project, then outputs structured markdown ready for Travis to paste into Beehiiv.
---

# Travis Media Weekly Newsletter Skill

This skill generates a weekly edition of THE Travis Media Newsletter — a curated roundup of AI, programming, and tech news sent via Beehiiv. The newsletter has a consistent structure, a conversational-but-informative voice, and always includes a hands-on "Try This in 5 Minutes" section with an open source tool.

## Newsletter Structure

Every issue follows this exact section order:

1. **Intro paragraph** — 2-3 sentences teasing the biggest stories this week. Conversational, gets right to the point.
2. **🚀 A Big Release / Headline Story** — The single most noteworthy release, launch, or announcement this week. 2 items: the news itself + a related deep-dive or analysis piece.
3. **🎬 Video of the Week** — `[PLACEHOLDER]` for Travis to insert his latest video. Include a placeholder title, description, and YouTube embed link spot.
4. **🛠️ Platform & Tools** — 2 items covering notable tool releases, platform changes, or developer workflow news.
5. **📚 Community Spotlight / Book Club / Promo** — `[PLACEHOLDER]` for Travis to insert community updates, book club info, or promotions. Include a note reminding Travis to fill this in.
6. **🧠 Community & Trends** — 2 items on broader industry trends, conference recaps, opinion pieces, or shifts in how developers work.
7. **⏱️ Try This in 5 Minutes** — A new-ish open source tool or project featured with a quick setup guide. This is a key section (see detailed instructions below).
8. **More Reading** — 4-6 additional links with one-line descriptions, covering items that didn't make the main sections.
9. **🗳️ Quick Poll (1-Click)** — A simple poll question related to this week's content, with 2-4 answer options.
10. **Sign-off** — "Until next week, Travis."

## Voice & Tone

- Write like a developer talking to other developers over coffee. Not stiff, not overly hyped.
- Short sentences. No filler. Every sentence earns its place.
- Bold key phrases within descriptions for scannability (e.g., "introducing **free-threaded builds**").
- Use link text that describes what the reader will find, not "click here."
- Emoji section headers are part of the brand — always use them.
- Travis refers to himself in first person in the intro and sign-off only. The rest is third-person journalistic.

## Research Process

When generating a newsletter edition, use web search to find content published **within the last 7 days** (or as close to current as possible). Search strategy:

1. **Headlines**: Search for major releases, launches, and announcements in AI, programming languages, developer tools, and tech platforms this week.
2. **Tools & Platforms**: Search for developer tool updates, IDE news, CI/CD changes, cloud platform announcements.
3. **Trends**: Search for industry analysis, conference recaps, opinion pieces about how development is changing.
4. **Open Source Project**: Search for trending GitHub repos, new open source tools, or recently released projects that a developer could try in 5 minutes (see below).
5. **More Reading**: Gather additional interesting links that didn't fit the main sections.

Aim for a mix of AI/ML news, programming language updates, and general developer tooling. Don't make it all AI — Travis's audience is developers broadly.

## Try This in 5 Minutes — Detailed Instructions

This is one of the newsletter's signature sections. The goal: feature an open source tool or project that a developer can install and get a meaningful result from in under 5 minutes.

**Finding the project:**
- Search for recently trending GitHub repos, new CLI tools, developer utilities, or interesting open source releases from the past ~2 weeks.
- Good candidates: CLI tools, language utilities, dev productivity tools, self-hosted apps, new frameworks with a quick-start.
- Bad candidates: Massive frameworks requiring 30 min setup, libraries with no standalone demo, tools requiring paid accounts.

**Writing the section:**
- Brief 1-2 sentence intro explaining what the tool does and why it's interesting.
- A code block with shell commands to install and run a quick demo. Should be copy-pasteable.
- A "Result:" line explaining what they'll see or what this proves.
- Keep it OS-agnostic where possible, or note if it's Mac/Linux only.

**Example format:**
```
## ⏱️ Try This in 5 Minutes

**[Tool Name]** — One sentence about what it does.

\`\`\`bash
# Install
pip install tool-name

# Quick demo
tool-name init my-project
cd my-project
tool-name run
\`\`\`

**Result:** What you'll see and why it matters.
```

## Poll / Quiz Guidelines

- The poll should relate to this week's content.
- Keep it simple: 2-4 answer options.
- Can be opinion-based ("Which AI tool do you use most?") or factual ("Have you tried X yet?").
- Phrase it so people want to click — mild curiosity or "where do you stand" energy.

## Output Format

Output the newsletter as **structured markdown** with clear section headers. Use this template:

```markdown
# [Emoji + Catchy Title Related to Top Story]

Hey everybody,

[2-3 sentence intro teasing the top stories this week. Conversational.]

---

## 🚀 [Headline Story Title]

### [Story 1 Title]
[2-3 sentence summary with **bold key terms** and [linked source](url).]

### [Story 2 - Related Analysis/Deep-Dive]
[1-2 sentence summary with [linked source](url).]

---

## 🎬 Video of the Week

> **[PLACEHOLDER: Insert this week's video]**
> Title: [Your video title here]
> Description: [Brief description]
> [YouTube link here]

---

## 🛠️ Platform & Tools

### [Tool/Platform Story 1]
[2-3 sentence summary with [linked source](url).]

### [Tool/Platform Story 2]
[1-2 sentence summary with [linked source](url).]

---

## 📚 [Community Spotlight / Book Club / Promo]

> **[PLACEHOLDER: Insert community update, book club info, or promo here]**
> [Notes for Travis about what to fill in]

---

## 🧠 Community & Trends

### [Trend Story 1]
[2-3 sentence summary with [linked source](url).]

### [Trend Story 2]
[1-2 sentence summary with [linked source](url).]

---

## ⏱️ Try This in 5 Minutes

**[Tool Name]** — [What it does in one sentence.]

\`\`\`bash
[Installation and demo commands]
\`\`\`

**Result:** [What they'll see and why it matters.]

---

## More Reading

- [Link text](url) — one-line description
- [Link text](url) — one-line description
- [Link text](url) — one-line description
- [Link text](url) — one-line description

---

## 🗳️ Quick Poll (1-Click)

**[Poll question related to this week's content]**

- Option A
- Option B
- Option C (optional)
- Option D (optional)

---

Until next week,
Travis.
```

## Placeholders Summary

These sections need Travis to fill in before publishing:
- **🎬 Video of the Week** — Insert video title, description, and link
- **📚 Community Spotlight** — Insert community/book club/promo content
- **All links** — Travis should add UTM parameters via Beehiiv (`?utm_source=newsletter.travis.media&utm_medium=newsletter&utm_campaign=SLUG`)
- **Poll** — Travis needs to create the actual poll in Beehiiv and link the options

## Quality Checklist

Before presenting the draft to Travis, verify:
- [ ] Every news item links to a real, current source (found via web search)
- [ ] The "Try This in 5 Minutes" project actually exists and commands are accurate
- [ ] No section is missing
- [ ] Mix of AI + programming + general tech (not all AI)
- [ ] Intro paragraph references the top 2-3 stories naturally
- [ ] Poll relates to something in this week's content
- [ ] Placeholders are clearly marked for Travis to fill in
