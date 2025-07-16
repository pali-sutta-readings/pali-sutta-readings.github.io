#set page(
  width: 210mm,
  height: 118.125mm,
  fill: rgb("282D3F"),
  header: none,
  footer: none,
  margin: 0pt,
  background: [
    #image("dhamma-wheel-white-20.png", width: 95%)
  ]
)
#set align(center + horizon)
#set text(font: "Noto Sans", size: 15pt, fill: luma(95%))
#set par(justify: false, spacing: 0pt, leading: 0pt)

#block(width: 100%, height: 65mm, above: 0pt, below: 0pt, fill: rgb("16423C").transparentize(10%))[
  #set par(justify: false, spacing: 1.0em)
  #line(length: 100%, stroke: 0.5pt + luma(45%))

  #v(20pt)

  #text(
    font: "Abhaya Libre X", size: 32pt, weight: "bold",
    top-edge: 0pt, bottom-edge: 0pt,
  )[Pāli Sutta Readings]

  #v(10mm)

  #text(
    font: "Noto Sans", size: 15pt,
    top-edge: 0pt, bottom-edge: 0pt,
  )[https://pali-sutta-readings.github.io]

  #v(20pt)

  #line(length: 100%, stroke: 0.5pt + luma(45%))
]
