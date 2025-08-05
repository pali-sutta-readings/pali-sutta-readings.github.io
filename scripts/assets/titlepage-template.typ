#let conf(
  date: none,
  doc,
) = {

set page(
  // ratio: 1080/1920 = 0.5625
  // A5 size: 148 x 210 mm
  width: 210mm,
  height: 118.125mm,
  fill: rgb("282D3F"),
  header: none,
  footer: none,
  margin: 0pt,
  background: [
    #image("dhamma-wheel-white-5.png", width: 95%)
  ]
)

set align(center + top)

set text(font: "Noto Sans", size: 15pt, fill: luma(95%))
set par(justify: false, spacing: 1.3em)
set list(indent: 1em)

show heading.where(level: 1): it => block(width: auto)[
  #set align(center)
  #set text(font: "Abhaya Libre X", size: 25pt, weight: "bold")
  #text(it.body)
  #v(0.3em)
]

show heading.where(level: 2): it => block(width: auto)[
  #set align(center)
  #set text(size: 15pt, weight: "bold")
  #v(0.8em)
  #text(it.body)
  #v(0.3em)
]

block(width: 100%, height: 30mm, above: 0pt, fill: rgb("16423C").transparentize(10%))[
#set align(bottom + center)

= Pāli Sutta Readings (#date)

#text(font: "Noto Sans", size: 11pt)[https://pali-sutta-readings.github.io]

#line(length: 100%, stroke: 0.5pt + luma(35%))

]

block(width: auto)[
#set align(left)

#doc

]

}
