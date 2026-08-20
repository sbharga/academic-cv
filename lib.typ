// ============================================================================
//  academic-cv — a black-and-white academic curriculum vitae for Typst
//
//  Built for documents that run to several pages: a running header from page
//  two onward, dated entries that align down the whole document, numbered
//  publication lists with hanging indents, and section headings that never get
//  stranded at the foot of a page.
//
//  Strictly monochrome. Emphasis comes from weight, size, spacing and rules —
//  never from colour.
// ============================================================================

// ---------------------------------------------------------------------------
//  Theme state — written once by `cv()`, read by every helper below.
// ---------------------------------------------------------------------------
#let __theme = state("academic-cv:theme", (
  ink: luma(10),
  muted: luma(90),
  rule: luma(160),
  size: 10.5pt,
  date-width: 24mm,
  gutter: 1.1em,
  date-position: "left",
  me-style: "bold",
))

// ---------------------------------------------------------------------------
//  Utilities
// ---------------------------------------------------------------------------

/// Full-width hairline.
#let hr(weight: 0.5pt, above: 0.7em, below: 0.7em) = context {
  block(
    above: above,
    below: below,
    line(length: 100%, stroke: weight + __theme.get().rule),
  )
}

/// Vertical space.
#let gap(amount: 0.7em) = v(amount, weak: true)

/// Your own name inside an author list, so it is easy to find in a long
/// bibliography. Style is set once via `me-style` in `cv()`.
#let me(name) = context {
  let s = __theme.get().me-style
  if s == "underline" { underline(name, offset: 0.15em) } else if s == "italic" {
    emph(name)
  } else if s == "none" { name } else { strong(name) }
}

/// Small right-aligned note, e.g. "(in press)" or "*equal contribution".
#let note(body) = context text(
  size: 0.88em,
  fill: __theme.get().muted,
  style: "italic",
  body,
)

// ---------------------------------------------------------------------------
//  Section headings
//  Write `= Publications` in your document, or call `#section[Publications]`.
// ---------------------------------------------------------------------------
#let section(body) = heading(level: 1, body)
#let subsection(body) = heading(level: 2, body)

// ---------------------------------------------------------------------------
//  dated — the workhorse row: a date in the left column, anything in the right.
//  Every dated row in the document lines up on the same axis.
// ---------------------------------------------------------------------------
#let dated(date, body, above: 0.62em, below: 0pt) = context {
  let t = __theme.get()
  let stamp = text(fill: t.muted, date)

  block(width: 100%, above: above, below: below, breakable: true, {
    if t.date-position == "right" {
      grid(
        columns: (1fr, auto),
        column-gutter: t.gutter,
        align: (left + top, right + top),
        body,
        stamp,
      )
    } else {
      grid(
        columns: (t.date-width, 1fr),
        column-gutter: t.gutter,
        align: (left + top, left + top),
        stamp,
        body,
      )
    }
  })
}

// ---------------------------------------------------------------------------
//  entry — a position, degree, award, grant or appointment.
//
//  #entry(
//    date: "2021 – present",
//    title: "Assistant Professor of Linguistics",
//    org: "University of Edinburgh",
//    location: "Edinburgh, UK",
//  )[ optional detail ]
// ---------------------------------------------------------------------------
#let entry(
  date: none,
  title: none,
  org: none,
  location: none,
  compact: false,
  ..args,
) = context {
  let t = __theme.get()
  let body = args.pos().at(0, default: none)

  let head = {
    if title != none { text(weight: 600, title) }
    if org != none {
      if title != none { [, ] }
      emph(org)
    }
    if location != none {
      if title != none or org != none { [, ] }
      text(fill: t.muted, location)
    }
  }

  dated(
    if date == none { [] } else { date },
    {
      // `sticky` glues the heading line to whatever follows it, so a title is
      // never left alone at the bottom of a page.
      block(sticky: true, spacing: 0pt, head)
      if body != none {
        block(above: 0.35em, below: 0pt, width: 100%, body)
      }
    },
    above: if compact { 0.42em } else { 0.62em },
  )
}

// ---------------------------------------------------------------------------
//  publications — numbered, hanging-indent lists.
//
//  #publications(
//    [Author, A. (2025). Title. *Journal*, 12(3), 1–20.],
//    [Author, A. (2024). …],
//    style: "descending",     // "descending" | "ascending" | "bullet" | "plain"
//  )
//
//  Descending numbering (newest = highest number) is the academic convention
//  and is the default: the list reads newest-first while the numbers stay
//  stable as you add work at the top.
// ---------------------------------------------------------------------------
#let publications(
  ..items,
  style: "descending",
  start: none, // override the first number
  marker-width: 1.6em,
  spacing: 0.62em,
  above: 0.5em,
  below: 0.2em,
) = context {
  let t = __theme.get()
  let list-items = items.pos()
  let n = list-items.len()

  let mark(i) = {
    if style == "descending" {
      let top = if start == none { n } else { start }
      [#(top - i).]
    } else if style == "ascending" {
      let first = if start == none { 1 } else { start }
      [#(first + i).]
    } else if style == "bullet" {
      [•]
    } else { [] }
  }

  block(width: 100%, above: above, below: below, grid(
    columns: if style == "plain" { (1fr,) } else { (marker-width, 1fr) },
    align: if style == "plain" { left } else { (right + top, left + top) },
    column-gutter: 0.55em,
    row-gutter: spacing,
    ..list-items
      .enumerate()
      .map(((i, it)) => if style == "plain" {
        (it,)
      } else {
        (text(fill: t.muted, mark(i)), it)
      })
      .flatten()
  ))
}

/// A single hanging-indent paragraph — for talks, posters, or any list where
/// numbering would be noise.
#let hanging(body, indent: 1.4em, above: 0.55em) = block(
  width: 100%,
  above: above,
  below: 0pt,
  par(hanging-indent: indent, body),
)

// ---------------------------------------------------------------------------
//  Labelled rows — languages, technical skills, memberships.
// ---------------------------------------------------------------------------
#let field(label, value) = context {
  let t = __theme.get()
  block(width: 100%, above: 0.45em, below: 0pt, grid(
    columns: (t.date-width, 1fr),
    column-gutter: t.gutter,
    text(fill: t.muted, label), value,
  ))
}

#let fields(..rows) = rows.pos().map(r => field(r.at(0), r.at(1))).join()

// ---------------------------------------------------------------------------
//  THE TEMPLATE
// ---------------------------------------------------------------------------
#let cv(
  // ── identity ──────────────────────────────────────────────────────────
  name: "Your Name",
  title: none, // e.g. "Assistant Professor of Linguistics"
  address: none, // department / institution block, content or array of lines
  contacts: (), // array of content, joined on one line
  updated: auto, // "Last updated" line; auto = today, none = omit

  // ── typography ────────────────────────────────────────────────────────
  font: (
    "Libertinus Serif",
    "EB Garamond",
    "TeX Gyre Pagella",
    "Bitstream Charter",
    "TeX Gyre Termes",
    "Georgia",
    "DejaVu Serif",
  ),
  size: 10.5pt,
  leading: 0.68em,
  justify: false,
  lang: "en",

  // ── monochrome palette (greys only) ───────────────────────────────────
  ink: luma(10), // body text
  muted: luma(95), // dates, secondary detail
  rule: luma(160), // hairlines

  // ── page ──────────────────────────────────────────────────────────────
  paper: "a4",
  margin: (top: 22mm, bottom: 20mm, x: 20mm),

  // ── layout ────────────────────────────────────────────────────────────
  date-position: "left", // "left" (academic default) | "right"
  date-width: 24mm, // width of the date column
  gutter: 1.1em, // space between date column and content

  // ── looks ─────────────────────────────────────────────────────────────
  header-align: center, // left | center
  name-size: 20pt,
  name-weight: 400,
  name-tracking: 0.06em,
  name-case: "upper", // "upper" | "normal"
  section-style: "rule", // "rule" | "plain" | "smallcaps"
  me-style: "bold", // how your own name is marked: bold|underline|italic|none
  running-header: auto, // auto | none | content — shown from page 2 onward
  page-numbers: true,

  body,
) = {
  let t = (
    ink: ink,
    muted: muted,
    rule: rule,
    size: size,
    date-width: date-width,
    gutter: gutter,
    date-position: date-position,
    me-style: me-style,
  )

  // ── document metadata ─────────────────────────────────────────────────
  set document(title: name + " — Curriculum Vitae", author: name)

  // ── running header, page two onward ───────────────────────────────────
  set page(
    paper: paper,
    margin: margin,
    header: context {
      if here().page() <= 1 { return }
      if running-header == none { return }
      set text(size: 0.86em, fill: muted)
      if running-header != auto {
        running-header
      } else {
        let total = counter(page).final().first()
        block(width: 100%, {
          grid(
            columns: (1fr, auto),
            align: (left, right),
            text(tracking: 0.04em, upper(name)),
            if page-numbers { [#here().page() of #total] },
          )
          v(0.35em)
          line(length: 100%, stroke: 0.4pt + rule)
        })
      }
    },
    header-ascent: 32%,
  )

  // ── base typography ───────────────────────────────────────────────────
  set text(font: font, size: size, fill: ink, lang: lang, hyphenate: false)
  set par(justify: justify, leading: leading, spacing: 0.62em)
  show link: it => it // links stay black; underline only if you add it

  set list(marker: [–], indent: 0em, body-indent: 0.55em, spacing: 0.45em)
  set enum(indent: 0em, body-indent: 0.55em, spacing: 0.45em)
  show list: set block(above: 0.4em, below: 0.4em)
  show enum: set block(above: 0.4em, below: 0.4em)

  // ── section headings ──────────────────────────────────────────────────
  show heading.where(level: 1): it => block(
    above: 1.5em,
    below: 0.7em,
    width: 100%,
    breakable: false,
    sticky: true,
    {
      set text(size: size * 1.0, weight: 600, fill: ink, tracking: 0.12em)
      if section-style == "smallcaps" {
        smallcaps(text(tracking: 0.06em, it.body))
      } else { upper(it.body) }
      if section-style != "plain" {
        v(0.34em, weak: true)
        line(length: 100%, stroke: 0.5pt + rule)
      }
    },
  )

  show heading.where(level: 2): it => block(
    above: 1.0em,
    below: 0.45em,
    sticky: true,
    text(size: size, weight: 600, style: "italic", fill: ink, it.body),
  )

  __theme.update(t)

  // ── masthead ──────────────────────────────────────────────────────────
  set align(header-align)

  block(spacing: 0pt, text(
    size: name-size,
    weight: name-weight,
    tracking: name-tracking,
    if name-case == "upper" { upper(name) } else { name },
  ))

  if title != none {
    v(0.5em)
    block(spacing: 0pt, text(size: size * 1.05, style: "italic", title))
  }

  if address != none {
    v(0.6em)
    let lines = if type(address) == array { address.join(linebreak()) } else {
      address
    }
    block(spacing: 0pt, text(size: size * 0.95, fill: muted, lines))
  }

  if contacts.len() > 0 {
    v(0.5em)
    block(spacing: 0pt, text(
      size: size * 0.95,
      fill: muted,
      contacts.join({
        h(0.45em)
        text(fill: rule, sym.bar.v)
        h(0.45em)
      }),
    ))
  }

  v(0.9em)
  line(length: 100%, stroke: 0.9pt + ink)

  if updated != none {
    v(0.3em)
    set align(right)
    text(size: size * 0.82, fill: muted, style: "italic", {
      [Last updated: ]
      if updated == auto {
        context datetime.today().display("[month repr:long] [year]")
      } else { updated }
    })
  }

  set align(left)
  v(0.2em)

  body
}
