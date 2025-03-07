#!/usr/bin/env python3

import sys
import subprocess
from typing import Optional, List
from pathlib import Path
import re

EXPORT_OPTIONS = "#+OPTIONS: tags:nil H:5"
RE_AUTHORS = re.compile(r'^\#\+authors:\s*(.*)\s*$', flags=re.MULTILINE)
RE_YOUTUBE_ID = re.compile(r'^\#\+youtube_id:\s*([^\s]+)\s*$', flags=re.MULTILINE)

def extract_authors(org_text: str) -> List[str]:
    m = RE_AUTHORS.search(org_text)
    if m is None:
        return []
    return [i.strip() for i in m.group(1).split(",")]

def extract_youtube_id(org_text: str) -> Optional[str]:
    m = RE_YOUTUBE_ID.search(org_text)
    return m.group(1) if m else None

def pandoc_convert(org_content: str, date: str, md_file: Path, exclude_from_search = False, extra_html = ""):
    # Check draft status
    is_draft = False
    if re.search(r'#\+draft:\s+t', org_content):
        is_draft = True

    # Remove LaTeX commands
    org_content = re.sub(r'^#\+latex:\s+.*$', '', org_content, flags=re.MULTILINE)
    org_content = re.sub(r'^\\[a-zA-Z].*$', '', org_content, flags=re.MULTILINE)

    youtube_id = extract_youtube_id(org_content)

    pandoc_cmd = [
        'pandoc',
        '-f', 'org+smart-auto_identifiers',
        '-t', 'gfm+smart-fenced_divs-gfm_auto_identifiers',
        '--wrap=none',
        '-o', str(md_file)
    ]

    process = subprocess.Popen(
        pandoc_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    _, error = process.communicate(org_content)

    if process.returncode != 0:
        raise RuntimeError(f"Pandoc failed: {error}")

    # The file name is the date, prepend it as a YAML header.
    # Add the excerpt marker after the YAML to effectively disable it.
    # Add the declensions legend div, only visible when printing.
    draft_line = "\ndraft: true" if is_draft else ""

    exclude_line =  "\nsearch:\n  exclude: true" if exclude_from_search else ""

    authors_line = f"\nauthors: [{", ".join(extract_authors(org_content))}]"

    yaml_header = f"""---{draft_line}{exclude_line}{authors_line}
date: {date}
---

<!-- more -->

{extra_html}
<div class='declensions'></div>

"""

    with open(md_file, 'r+', encoding='utf-8') as f:
        md_content = f.read()

        # Add the YouTube embed html after the first lvl1 heading.
        if youtube_id:
            m = re.search(r'^#\s+(.+)$\n', md_content, flags=re.MULTILINE)
            if m:
                youtube_embed_html = f"""\n<iframe width="750" height="420" src="https://www.youtube.com/embed/{youtube_id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>\n"""
                start_pos = m.end()
                md_content = md_content[:start_pos] + youtube_embed_html + md_content[start_pos:]

        f.seek(0)
        f.write(yaml_header + md_content)
        f.truncate()

def convert_org_to_md(org_file: Path, md_sessions_dir: Path, md_print_dir: Path):
    if not org_file.exists():
        raise FileNotFoundError(f"Input file {org_file} not found")

    md_sessions_dir.mkdir(parents=True, exist_ok=True)

    # Get base filename
    date = org_file.stem
    md_file = md_sessions_dir.joinpath(f"{date}.md")

    try:
        with open(org_file, 'r', encoding='utf-8') as f:
            org_content = f.read()

        # Check for longtable environment
        # Keep only the first two columns of tables, the other columns are used for hidden info.
        if re.search(r':environment\s+longtable', org_content):
            org_content = re.sub(r'^(\|[^\|]+\|[^\|]+\|).*$', r'\1', org_content, flags=re.MULTILINE)

        exclude_tags = ["noexport"]

        # Prepend export options
        options = EXPORT_OPTIONS + "\n#+EXCLUDE_TAGS: " + " ".join(exclude_tags) + "\n\n"

        web_org_content = options + org_content
        pandoc_convert(web_org_content, date, md_file)

        print(f"Converted to: {md_file}")

        md_print_dir.mkdir(parents=True, exist_ok=True)

        print_md_file = md_print_dir.joinpath(md_file.name)

        exclude_tags.append("noprint")
        options = EXPORT_OPTIONS + "\n#+EXCLUDE_TAGS: " + " ".join(exclude_tags) + "\n\n"

        print_org_content = options + org_content
        # Remove the youtube_id for the print page.
        print_org_content = RE_YOUTUBE_ID.sub('', print_org_content)
        pandoc_convert(print_org_content, date, print_md_file, exclude_from_search=True)

        print(f"Converted to: {print_md_file}")

    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: org_to_md.py <input_org_file> <web_md_dir> <print_md_dir>")
        sys.exit(1)

    convert_org_to_md(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
