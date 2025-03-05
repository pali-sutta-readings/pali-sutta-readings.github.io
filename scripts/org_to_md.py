#!/usr/bin/env python3

import sys
import subprocess
from pathlib import Path
import re

def pandoc_convert(org_content: str, date: str, md_file: Path, exclude_from_search = False, extra_html = ""):
    # Check draft status
    is_draft = False
    if re.search(r'#\+draft:\s+t', org_content):
        is_draft = True

    # Remove LaTeX commands
    org_content = re.sub(r'^#\+latex:\s+.*$', '', org_content, flags=re.MULTILINE)
    org_content = re.sub(r'^\\[a-zA-Z].*$', '', org_content, flags=re.MULTILINE)

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

    yaml_header = f"""---{draft_line}{exclude_line}
date: {date}
---

<!-- more -->

{extra_html}
<div class='declensions'></div>

"""

    with open(md_file, 'r+', encoding='utf-8') as f:
        content = f.read()
        f.seek(0)
        f.write(yaml_header + content)
        f.truncate()

def convert_org_to_md(org_file: Path, md_sessions_dir: Path):
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
        options = "#+OPTIONS: tags:nil\n#+EXCLUDE_TAGS: " + " ".join(exclude_tags) + "\n\n"

        web_org_content = options + org_content
        pandoc_convert(web_org_content, date, md_file)

        print(f"Converted to: {md_file}")

        print_md_dir = md_file.parent.parent.parent.joinpath("readings-print")
        print_md_dir.mkdir(parents=True, exist_ok=True)

        print_md_file = print_md_dir.joinpath(md_file.name)

        exclude_tags.append("noprint")
        options = "#+OPTIONS: tags:nil\n#+EXCLUDE_TAGS: " + " ".join(exclude_tags) + "\n\n"

        print_org_content = options + org_content
        pandoc_convert(print_org_content, date, print_md_file, exclude_from_search=True)

        print(f"Converted to: {print_md_file}")

    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_org_file> <output_directory>")
        sys.exit(1)

    convert_org_to_md(Path(sys.argv[1]), Path(sys.argv[2]))
