#!/bin/bash
# Build the GitHub Pages site under docs/ from the book in tasting/.
#
# For the book it: runs the Makefile to build the PDFs, converts every
# chapter, the conclusion, the appendices, and the answer key to a Jekyll
# page under docs/tasting/, copies the PDFs next to them, builds one
# self-contained single-page HTML of the whole book, and writes the
# chapter list include that docs/tasting.md pulls in.
set -euo pipefail
shopt -s nullglob

DOCS=docs
INCLUDES=$DOCS/_includes
PANDOC_OPTS="-f markdown -t html5 --highlight-style=pygments --wrap=none --email-obfuscation=none"

# Inline SVG used as a PDF icon. Kept as a single line so it drops cleanly
# into generated HTML includes.
PDF_ICON_SVG='<svg class="pdf-icon" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg>'

# Open-book SVG icon for the single-page HTML link.
SINGLE_PAGE_ICON_SVG='<svg class="pdf-icon" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>'

get_heading() {
    grep -m1 '^#\+ ' "$1" | sed -e 's/^#\+ //' -e 's/[[:space:]]*{[^}]*}[[:space:]]*$//'
}

# The pandoc filters a book uses, as command-line options, run from the
# book directory. callout.lua renders the ::: {.tip} divs, session.lua the
# ```session terminal blocks.
filter_opts() {
    local src_dir="$1" opts=""
    for f in callout.lua session.lua; do
        [ -f "$src_dir/$f" ] && opts="$opts --lua-filter=$f"
    done
    echo "$opts"
}

# Citation options when the book has a bibliography. Chapter pages that
# cite something get their own reference list at the end; appending
# bibliography.md gives that list its heading (its raw LaTeX lines are
# dropped by the HTML writer).
cite_opts() {
    local src_dir="$1" opts=""
    if [ -f "$src_dir/references.bib" ]; then
        opts="--citeproc --bibliography=references.bib"
        [ -f "$src_dir/ieee.csl" ] && opts="$opts --csl=ieee.csl"
    fi
    echo "$opts"
}

convert_chapter() {
    local src_dir="$1" md_base="$2" dest="$3" title="$4" parent="$5" nav_order="$6"
    local extra_opts="${7:-}"

    mkdir -p "$(dirname "$dest")"

    local filter_opt cite_opt refs=""
    filter_opt=$(filter_opts "$src_dir")
    cite_opt=$(cite_opts "$src_dir")
    if [ -n "$cite_opt" ] && grep -q '\[@' "$src_dir/$md_base" && [ -f "$src_dir/bibliography.md" ]; then
        refs="bibliography.md"
    fi

    {
        printf '%s\n' "---"
        printf 'layout: default\n'
        printf 'title: "%s"\n' "$title"
        printf 'parent: "%s"\n' "$parent"
        printf 'nav_order: %s\n' "$nav_order"
        printf '%s\n\n' "---"
        printf '{%% raw %%}\n'
        (cd "$src_dir" && pandoc "$md_base" $refs $PANDOC_OPTS $filter_opt $cite_opt $extra_opts)
        printf '\n{%% endraw %%}\n'
    } > "$dest"
}

# Run the book's Makefile to build its PDFs. Does not fail the whole site
# build if a book's PDFs can't be built; the pipeline still produces HTML.
build_book_pdfs() {
    local src_dir="$1"
    if [ ! -f "$src_dir/Makefile" ]; then
        return
    fi
    echo "building PDFs in $src_dir"
    # -k: keep going after an error so one bad target doesn't block the other PDFs.
    # -j4: build up to four PDF targets in parallel within this book.
    if ! (cd "$src_dir" && make -k -j4 all chapters); then
        echo "warning: one or more PDF targets failed for $src_dir --- site will use whatever PDFs were produced" >&2
    fi
}

# Build a single self-contained HTML page for the whole book.
#
# Each callout icon kind (tip/trap/wut) is base64-encoded exactly once into a
# <style> block injected via --include-in-header.  callout.lua emits a CSS
# class span instead of an <img> when --metadata single-page-callouts=true is
# set, so the data URI never repeats no matter how many callout boxes exist.
# book.css is also inlined in the same <style> block, and the copy button
# script after it; no --embed-resources needed.
build_single_page() {
    local src_dir="$1" dest_subdir="$2" title="$3"
    local html_dst="$DOCS/$dest_subdir/${dest_subdir}-book.html"
    local abs_dst
    abs_dst="$(pwd)/$html_dst"
    mkdir -p "$DOCS/$dest_subdir"

    echo "building single-page HTML for $dest_subdir"

    # Same source order as the per-chapter build: chapters, conclusion,
    # appendices, references.
    local srcs=()
    [ -f "$src_dir/author-intro.md" ] && srcs+=("author-intro.md")
    for md in "$src_dir"/ch[0-9][0-9].md; do srcs+=("$(basename "$md")"); done
    [ -f "$src_dir/conclusion.md" ] && srcs+=("conclusion.md")
    for md in "$src_dir"/app*.md;         do srcs+=("$(basename "$md")"); done
    [ -f "$src_dir/bibliography.md" ] && srcs+=("bibliography.md")

    local filter_opt cite_opt
    filter_opt=$(filter_opts "$src_dir")
    cite_opt=$(cite_opts "$src_dir")

    # Build the injected <style> block: book.css + one data URI per icon kind.
    local header_file
    header_file=$(mktemp "${TMPDIR:-/tmp}/book-header-XXXXXX.html")
    {
        printf '<style>\n'
        [ -f "$src_dir/book.css" ] && cat "$src_dir/book.css" && printf '\n'
        printf '.callout-icon {\n'
        printf '  display: inline-block; flex-shrink: 0;\n'
        printf '  width: 48px; height: 48px;\n'
        printf '  background-size: contain; background-repeat: no-repeat;\n'
        printf '  background-position: center;\n'
        printf '}\n'
        for kind in tip trap wut; do
            local img="$src_dir/../images/${kind}-callout.png"
            [ -f "$img" ] && printf '.callout-%s{background-image:url("data:image/png;base64,%s")}\n' \
                "$kind" "$(base64 -w0 "$img")"
        done
        printf '</style>\n'
        # The copy button script the Jekyll pages load, inlined.
        if [ -f "$DOCS/assets/js/copy-code.js" ]; then
            printf '<script>\n'
            cat "$DOCS/assets/js/copy-code.js"
            printf '</script>\n'
        fi
    } > "$header_file"

    if ! (cd "$src_dir" && pandoc "${srcs[@]}" \
            -f markdown -t html5 \
            $filter_opt \
            $cite_opt \
            --standalone \
            --toc \
            --toc-depth=2 \
            --highlight-style=pygments \
            --wrap=none \
            --email-obfuscation=none \
            --metadata title="$title" \
            --metadata single-page-callouts=true \
            --include-in-header="$header_file" \
            -o "$abs_dst"); then
        echo "warning: single-page HTML build failed for $dest_subdir" >&2
    fi
    rm -f "$header_file"
}

# Copy a PDF into the docs tree if it exists.
copy_pdf() {
    local src="$1" dst="$2"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
}

# Emit an entry for the chapter list include: chapter title link + optional PDF icon.
emit_chapter_entry() {
    local dest_subdir="$1" base_noext="$2" title="$3" include_pdf="$4"
    printf '  <li>\n'
    printf "    <a href=\"{{ '/%s/%s.html' | relative_url }}\">%s</a>\n" \
        "$dest_subdir" "$base_noext" "$title"
    if [ "$include_pdf" = "yes" ]; then
        printf "    <a class=\"chapter-pdf-link\" href=\"{{ '/%s/%s.pdf' | relative_url }}\" title=\"Download chapter PDF\" aria-label=\"Download %s PDF\">%s</a>\n" \
            "$dest_subdir" "$base_noext" "$title" "$PDF_ICON_SVG"
    fi
    printf '  </li>\n'
}

build_book() {
    local src_dir="$1" dest_subdir="$2" parent="$3" book_slug="$4"

    build_book_pdfs "$src_dir"
    build_single_page "$src_dir" "$dest_subdir" "$parent"

    local include_file="$INCLUDES/${dest_subdir}-chapters.html"
    mkdir -p "$INCLUDES" "$DOCS/$dest_subdir"

    # Full book and answer key PDFs get copied next to the chapter PDFs.
    local full_pdf_src="$src_dir/${book_slug}.pdf"
    local full_pdf_dst="$DOCS/$dest_subdir/${dest_subdir}.pdf"
    local answers_pdf_src="$src_dir/${book_slug}-answers.pdf"
    local answers_pdf_dst="$DOCS/$dest_subdir/${dest_subdir}-answers.pdf"
    local single_html_dst="$DOCS/$dest_subdir/${dest_subdir}-book.html"
    copy_pdf "$full_pdf_src" "$full_pdf_dst"
    copy_pdf "$answers_pdf_src" "$answers_pdf_dst"

    {
        printf '<!-- generated by build-site.sh; do not edit -->\n'

        # Top-of-page download/read links.
        if [ -f "$full_pdf_dst" ] || [ -f "$answers_pdf_dst" ] || [ -f "$single_html_dst" ]; then
            printf '<p class="book-pdf-links">\n'
            if [ -f "$full_pdf_dst" ]; then
                printf "  <a class=\"book-pdf-link\" href=\"{{ '/%s/%s.pdf' | relative_url }}\">%s Full book PDF</a>\n" \
                    "$dest_subdir" "$dest_subdir" "$PDF_ICON_SVG"
            fi
            if [ -f "$answers_pdf_dst" ]; then
                printf "  <a class=\"book-pdf-link\" href=\"{{ '/%s/%s-answers.pdf' | relative_url }}\">%s Answer key PDF</a>\n" \
                    "$dest_subdir" "$dest_subdir" "$PDF_ICON_SVG"
            fi
            if [ -f "$single_html_dst" ]; then
                printf "  <a class=\"book-pdf-link\" href=\"{{ '/%s/%s-book.html' | relative_url }}\">%s Read as single page</a>\n" \
                    "$dest_subdir" "$dest_subdir" "$SINGLE_PAGE_ICON_SVG"
            fi
            printf '</p>\n'
        fi

        printf '<ul class="chapter-list">\n'

        # Author intro (if present) renders before chapter 0.
        if [ -f "$src_dir/author-intro.md" ]; then
            local author_title author_dest
            author_title=$(get_heading "$src_dir/author-intro.md")
            author_dest="$DOCS/$dest_subdir/author-intro.html"
            convert_chapter "$src_dir" "author-intro.md" "$author_dest" \
                "$author_title" "$parent" "-1"
            emit_chapter_entry "$dest_subdir" "author-intro" "$author_title" "no"
        fi

        for md in "$src_dir"/ch[0-9][0-9].md; do
            local base num chapnum title html_dest pdf_src pdf_dst include_pdf number_opts
            base=$(basename "$md")
            num=${base%.md}
            num=${num#ch}
            chapnum=$((10#$num))
            title="${chapnum}. $(get_heading "$md")"
            html_dest="$DOCS/$dest_subdir/${base%.md}.html"

            # Auto-number chapter headings to match the PDF.
            number_opts="--number-sections --number-offset=$((chapnum - 1))"

            convert_chapter "$src_dir" "$base" "$html_dest" "$title" "$parent" "$chapnum" "$number_opts"

            pdf_src="$src_dir/${base%.md}.pdf"
            pdf_dst="$DOCS/$dest_subdir/${base%.md}.pdf"
            copy_pdf "$pdf_src" "$pdf_dst"
            if [ -f "$pdf_dst" ]; then include_pdf=yes; else include_pdf=no; fi

            emit_chapter_entry "$dest_subdir" "${base%.md}" "$title" "$include_pdf"
        done

        # Conclusion (if present) sits between the chapters and the appendices.
        if [ -f "$src_dir/conclusion.md" ]; then
            local conclusion_title
            conclusion_title=$(get_heading "$src_dir/conclusion.md")
            convert_chapter "$src_dir" "conclusion.md" "$DOCS/$dest_subdir/conclusion.html" \
                "$conclusion_title" "$parent" 50
            emit_chapter_entry "$dest_subdir" "conclusion" "$conclusion_title" "no"
        fi

        for md in "$src_dir"/app*.md; do
            local base letter order title html_dest pdf_src pdf_dst include_pdf
            base=$(basename "$md")
            letter=${base%.md}
            letter=${letter#app}
            order=$((100 + $(printf '%d' "'$letter") - $(printf '%d' "'A")))
            title="Appendix ${letter}: $(get_heading "$md")"
            html_dest="$DOCS/$dest_subdir/${base%.md}.html"

            convert_chapter "$src_dir" "$base" "$html_dest" "$title" "$parent" "$order"

            pdf_src="$src_dir/${base%.md}.pdf"
            pdf_dst="$DOCS/$dest_subdir/${base%.md}.pdf"
            copy_pdf "$pdf_src" "$pdf_dst"
            if [ -f "$pdf_dst" ]; then include_pdf=yes; else include_pdf=no; fi

            emit_chapter_entry "$dest_subdir" "${base%.md}" "$title" "$include_pdf"
        done

        printf '</ul>\n'

        if [ -f "$src_dir/${book_slug}-answers.md" ]; then
            convert_chapter "$src_dir" "${book_slug}-answers.md" \
                "$DOCS/$dest_subdir/answers.html" "Answer Key" "$parent" 200
        fi
    } > "$include_file"
}

build_book tasting  tasting  "Gorgo Tasting OpenTofu and Terraform"  "tofu"

echo "site built successfully"
