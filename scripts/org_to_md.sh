#!/usr/bin/env bash

org_file="$1"
MD_SESSIONS_DIR="$2"

name=$(basename "$org_file" .org)
md_file="$MD_SESSIONS_DIR/$name.md"

cat "$org_file" |\
    # Prepend export options
    sed "1i#+OPTIONS: tags:nil\n\n" |\
    # Remove LaTeX commands
    grep -vE '^#\+latex:|^\\[a-zA-Z]' |\
    # LaTeX quote marks
    sed -e 's/``/"/g; s/'"''"'/"/g; s/`/'"'"'/g;' |\
    # convert definition list to plain list
    sed -e 's/^- \([^:]\+\) *:: *\(.*\)/- *\1,* \2/; s/ \+\(,\*\)/\1/;' |\
    # clean spaces and remove repeated blanks
    sed 's/^ *$//' |\
    # Keep only the first two columns of tables, the other columns are used for hidden info.
    sed -E 's/^(\|[^\|]+\|[^\|]+\|).*/\1/' |\
    cat -s |\
    pandoc -f org+smart-auto_identifiers -t gfm+smart-fenced_divs-gfm_auto_identifiers --wrap=none -o "$md_file"

if grep -q "#+draft: t" "$org_file"; then
    draft="\ndraft: true"
else
    draft=""
fi

# The file name is the date, prepend it as a YAML header.
# Add the excerpt marker after the YAML to effectively disable it.
# Add the declensions legend div, only visible when printing.
sed -i "1i---$draft\ndate: $name\n---\n\n<!-- more -->\n\n<div class='declensions'></div>\n\n" "$md_file"

# Remove empty table headers
# NOTE: This breaks the mkdocs table syntax.
#
# |  |  |  |  |
# |----|----|----|----|
# sed -Ei 's/^\|  \|[ \|]+$//' "$md_file"
# sed -Ei 's/^\|----\|[-\|]+$//' "$md_file"

echo "Converted to: $md_file"
