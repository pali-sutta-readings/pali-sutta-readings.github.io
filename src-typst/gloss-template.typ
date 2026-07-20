// Pandoc Typst template for Pāli reading gloss exports.
//
// Reproduces the browser print view defined in docs/assets/css/extra.css:
//   - A4 page, 1.5cm margins all around
//   - H1: Abhaya Libre X, 20pt, bold, with a bottom rule
//   - H2: Noto Serif, 12pt, bold
//   - H3: Noto Serif, 11pt, bold
//   - Body: Crimson Text, 11pt / 15pt line height
//   - Blockquotes: indented 2em left and right, no border
//   - Gloss tables: borderless, headword column auto-width, gloss column
//     filling the rest, with generous right padding (7em in the CSS)
//
// Used by scripts/org_to_pdf_watch.sh via:
//   pandoc -f org -t typst --template src-typst/gloss-template.typ ...

#set document(title: "$title$")

#set page(
  paper: "a4",
  margin: 1.5cm,
)

// Normalise the line box to exactly 1em (0.75em - (-0.25em)) so that the
// paragraph leading below maps directly to a CSS-style line height.
#set text(
  font: "Crimson Text",
  size: 11pt,
  lang: "en",
  top-edge: 0.75em,
  bottom-edge: -0.25em,
)

// line-height: 1.5  ->  1em line box + 0.5em leading. Applies to body text,
// blockquotes and table rows alike.
#set par(
  leading: 0.5em,
  spacing: 0.9em,
  justify: false,
)

#let horizontalrule = line(start: (25%, 0%), end: (75%, 0%))

// --- Headings -------------------------------------------------------------

#show heading.where(level: 1): it => {
  set text(font: "Abhaya Libre X", weight: 700, size: 20pt)
  block(
    width: 100%,
    below: 0.9em,
    stroke: (bottom: 0.4pt + black),
    inset: (bottom: 0.12em),
    it.body,
  )
}

#show heading.where(level: 2): it => {
  set text(font: "Abhaya Libre X", weight: "bold", size: 16pt)
  block(above: 1.3em, below: 0.7em, it.body)
}

#show heading.where(level: 3): it => {
  set text(font: "Noto Serif", weight: "bold", size: 12pt)
  block(above: 1em, below: 0.6em, it.body)
}

// --- Blockquotes ----------------------------------------------------------

#show quote.where(block: true): it => block(
  width: 100%,
  inset: (left: 2em),
  it.body,
)

// --- Gloss tables ---------------------------------------------------------

#set table(
  stroke: none,
  inset: (right: 1.2em, y: 3pt),
  align: left + top,
)

// The conversion step (scripts/org_to_pdf_watch.sh) strips pandoc's figure
// wrapper so tables are emitted bare. Let each gloss table break across pages;
// it extends to the full text width on the right.
#show table: it => block(
  width: 100%,
  breakable: true,
  it,
)

$body$
