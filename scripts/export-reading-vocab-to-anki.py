#!/usr/bin/env python3

import os
import sys
import re
import csv
from pathlib import Path
from typing import TypedDict, Dict, List
from mako.template import Template

from helpers import VocabSection, anki_invoke, get_word_by_dpd_id, get_org_vocab_sections, normalize_sutta_ref

DECK_MAIN = "Pāli Readings"
BASIC_MODEL = "Basic (and reversed card)"
CLOZE_MODEL = "Cloze"

class NoteExample(TypedDict):
    reading_example: str
    reading_source: str

class NoteData(TypedDict):
    dpd_id: str # 40862
    full_deck_name: str
    word_json: Dict[str, str]
    examples: List[NoteExample]

class AnkiNote(TypedDict):
    # full deck name, e.g. "Pāli Readings::AN 10.81 Vāhanasutta"
    deckName: str
    # "Basic (and reversed card)" or "Cloze"
    modelName: str
    # {"Front": basic_front, "Back": basic_back} or {"Text": cloze_card}
    fields: Dict[str, str]

def create_tsv_export(anki_notes: List[AnkiNote], org_path: Path):
    print("=== Export to .tsv ===")

    tsv_basic_path = Path(f"{org_path.stem}-basic.tsv")
    tsv_cloze_path = Path(f"{org_path.stem}-cloze.tsv")

    basic_notes = [i["fields"] for i in anki_notes if i["modelName"] == BASIC_MODEL]
    cloze_notes = [i["fields"] for i in anki_notes if i["modelName"] == CLOZE_MODEL]

    with open(tsv_basic_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=["Front", "Back"], delimiter='\t')
        w.writeheader()
        w.writerows(basic_notes)

    with open(tsv_cloze_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=["Text"], delimiter='\t')
        w.writeheader()
        w.writerows(cloze_notes)

def create_apkg_export(anki_notes: List[AnkiNote], org_path: Path, clean_up = True):
    print("=== Import to Anki and export to .apkg ===")
    apkg_path = org_path.with_suffix(".apkg")

    print("=== Change to 'testing' profile and remove decks ===")
    # Change to the 'testing' profile.
    anki_invoke("loadProfile", params={"name": "testing"})

    # Delete any Pāli Readings decks before generating new ones
    anki_invoke("deleteDecks", params={"decks": [DECK_MAIN], "cardsToo": True})

    print("=== Creating Anki decks ===")
    deck_names = list(set([i["deckName"] for i in anki_notes]))
    for i in deck_names:
        print(i)
        anki_invoke("createDeck", params={"deck": i})

    res = anki_invoke("canAddNotesWithErrorDetail", params={"notes": anki_notes})
    for idx, i in enumerate(res):
        if not i['canAdd']:
            print(anki_notes[idx])
            print(i['error'])

    print("=== Add Anki notes ===")
    anki_invoke("addNotes", params={"notes": anki_notes})

    anki_invoke("exportPackage", params={
        "deck": DECK_MAIN,
        "path": os.path.abspath(str(apkg_path)),
        "includeSched": False,
    })

    if clean_up:
        print("=== Clean up: removing decks ===")
        anki_invoke("deleteDecks", params={"decks": [DECK_MAIN], "cardsToo": True})

def add_vocab_from_section(sec: VocabSection,
                           vocab: Dict[str, NoteData],
                           reading_source: str):
    for line in sec['content'].split("\n"):
        m = re.search(r"\| *([0-9]+)/dpd *\|([^\|]+)\|", line)
        if m is None:
            continue
        else:
            dpd_id = m.group(1)

            # Replace the markers {{  }} with <b> </b>
            reading_example = m.group(2).replace("{{", "<b>").replace("}}", "</b>")

            # dpd_id as key ensures that only the first instance of the same
            # word per sutta (reading_source) is kept, including if later
            # readings include the same word again in the sutta.
            #
            # reading_example is thus the first case where the word was
            # encountered in the sutta.
            if dpd_id not in vocab.keys():
                vocab[dpd_id] = NoteData(
                    dpd_id = dpd_id,
                    full_deck_name = f"{DECK_MAIN}::{reading_source}",
                    word_json = get_word_by_dpd_id(dpd_id),
                    examples = [
                        NoteExample(
                            reading_example = reading_example,
                            reading_source = reading_source,
                        ),
                    ],
                )

            else:
                # If the word has already been added, append the new example.
                vocab[dpd_id]["examples"].append(
                    NoteExample(
                        reading_example = reading_example,
                        reading_source = reading_source,
                    )
                )

def render_anki_notes(vocab: Dict[str, NoteData],
                      front_tmpl: Template) -> List[AnkiNote]:
    anki_notes: List[AnkiNote] = []

    for d in vocab.values():
        basic_front = str(front_tmpl.render(
            d = d,
            w = d["word_json"],
            normalize_sutta_ref = normalize_sutta_ref,
        ))

        meaning = d["word_json"]["meaning_1"]
        if d["word_json"]["meaning_lit"] != "":
            meaning = meaning.strip() + "; lit. " + d["word_json"]["meaning_lit"]

        basic_back = f"""<div style="font-size: 1em; padding: 1em;">{meaning}</div>"""

        anki_notes.append(AnkiNote(
            deckName = d["full_deck_name"],
            modelName = BASIC_MODEL,
            fields = {"Front": basic_front, "Back": basic_back},
        ))

        for ex in d["examples"]:
            if "<b>" in ex["reading_example"]:
                cloze_text = ex["reading_example"] \
                    .replace("<b>", "<b>{{c1::") \
                    .replace("</b>", "}}</b>")

                cloze_card = f""" <div style="line-height: 1.6; text-align: left; max-width: 52ex; padding: 1em; margin: 0 auto;">{cloze_text}</div> """

                anki_notes.append({
                    "deckName": d["full_deck_name"],
                    "modelName": CLOZE_MODEL,
                    "fields": {"Text": cloze_card},
                })

    return anki_notes

def export_vocab(org_path: Path):
    with open(org_path, 'r', encoding='utf-8') as f:
        content = f.read()

    sections = get_org_vocab_sections(content, keep_only_tag=':anki:')

    with open(Path(__file__).parent.joinpath("anki_vocab_front.mako.html"), 'r', encoding="utf-8") as f:
        html_content = f.read()

    front_tmpl = Template(html_content)
    # DPD ID to data
    vocab: Dict[str, NoteData] = {}
    # For anki_invoke
    anki_notes: List[AnkiNote] = []

    print("=== Extract vocabulary from sections ===")
    for sec in sections:
        print(f"- {sec['title']}")

        if sec["deck_name"]:
            reading_source = sec['deck_name']
        else:
            reading_source = sec['title']

        # Extract DPD word ids (40862/dpd -> 40862) from tables,
        # and the example sentences.
        add_vocab_from_section(sec, vocab, reading_source)

    print("=== Render anki notes ===")
    anki_notes = render_anki_notes(vocab, front_tmpl)

    create_apkg_export(anki_notes, org_path)

if __name__ == "__main__":
    usage = f"""Usage:\n{Path(__file__).name} <pali-readings.org>"""

    if len(sys.argv) < 2:
        print(usage)
        sys.exit(2)

    org_path = Path(sys.argv[1])

    if org_path.exists():
        export_vocab(org_path)

    else:
        print(f"File doesn't exist: {org_path}")
