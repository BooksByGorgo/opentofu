-- Callout filter: handles ::: {.tip} divs and differentiates Tip / Trap /
-- Wut by inspecting the bold label on the first line of the content. The
-- box is split into two columns: the icon sits in a narrow left column
-- and the text fills the right column, so the text does not wrap around
-- the icon. We point at the -callout.png downsized variants (256x256,
-- ~100KB each) so chapter PDFs do not bloat the way they would if we
-- embedded the 1024x1024 source PNGs. The path ../images/<kind>-callout
-- .png works for both LaTeX (pandoc runs in the book directory, and the
-- images live one level up) and HTML (a Jekyll chapter page lives at
-- docs/<book>/chNN.html and the images at docs/images/).

local tcb = "colback=black!5, colframe=black!20, " ..
  "boxrule=0.4pt, arc=2pt, left=5pt, right=5pt, " ..
  "top=4pt, bottom=4pt, fontupper=\\small"

-- sidebyside splits the box into two columns. lefthand width sets the
-- width of the icon column; the rest goes to the text column. The
-- lower separated=false option suppresses tcolorbox's default thin
-- rule between the upper (icon) and lower (text) segments.
-- sidebyside align=top seam aligns the icon's top with the text
-- baseline area (accounting for box padding) so the icon sits level
-- with the first line of text rather than floating above it.
local tcb_icon = tcb ..
  ", sidebyside, sidebyside align=top seam, sidebyside gap=8pt, " ..
  "lefthand width=0.45in, lower separated=false"

local html_style = "background-color: #f5f5f5; border: 1px solid #ccc; " ..
  "border-radius: 4px; padding: 12px 16px; margin: 1em 0; font-size: 0.95em;"

-- When true the HTML path emits a CSS-class span instead of an <img> so
-- the base64 data URI for each icon kind appears only once in the document
-- (in a <style> block injected via --include-in-header by build-site.sh).
local single_page_callouts = false

function Meta(m)
  if m['single-page-callouts'] then single_page_callouts = true end
end

-- Map the bold label text at the start of a callout to its icon basename.
local function callout_kind(el)
  for _, block in ipairs(el.content) do
    if block.t == "Para" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Strong" then
          local label = pandoc.utils.stringify(inline)
          if label == "Tip:"  then return "tip"  end
          if label == "Trap:" then return "trap" end
          if label == "Wut:"  then return "wut"  end
        end
      end
    end
  end
  return nil
end

local function clean_callout_blocks(content)
  local new_blocks = pandoc.List({})
  for i, block in ipairs(content) do
    if i == 1 and block.t == "Para" then
      local new_inlines = pandoc.List({})
      local stripping = true
      for _, inline in ipairs(block.content) do
        if stripping and (inline.t == "SoftBreak" or inline.t == "Space") then
          -- skip softbreak/space before/between leading raw index inlines
        else
          if inline.t ~= "RawInline" then
            stripping = false
          end
          new_inlines:insert(inline)
        end
      end
      new_blocks:insert(pandoc.Para(new_inlines))
    else
      new_blocks:insert(block)
    end
  end
  return new_blocks
end

local function Div(el)
  if not el.classes:includes("tip") then return nil end

  local kind = callout_kind(el)
  local fmt = FORMAT

  if fmt:match("latex") then
    local blocks = pandoc.List({})
    if kind then
      -- Two-column box: icon in the left column, pandoc-emitted content
      -- (everything between \tcblower and \end{tcolorbox}) in the right.
      blocks:insert(pandoc.RawBlock("latex",
        "\\begin{tcolorbox}[" .. tcb_icon .. "]"))
      blocks:insert(pandoc.RawBlock("latex",
        "\\vspace*{0.5\\baselineskip}\\includegraphics[width=\\linewidth]{../images/"
        .. kind .. "-callout.png}"))
      blocks:insert(pandoc.RawBlock("latex", "\\tcblower"))
      local cleaned = clean_callout_blocks(el.content)
      for _, cb in ipairs(cleaned) do
        blocks:insert(cb)
      end
      blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    else
      -- No recognized label --- fall back to the plain single-column box.
      blocks:insert(pandoc.RawBlock("latex",
        "\\begin{tcolorbox}[" .. tcb .. "]"))
      for _, cb in ipairs(el.content) do
        blocks:insert(cb)
      end
      blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    end
    return blocks

  elseif fmt:match("html") then
    local blocks = pandoc.List({})
    if kind then
      -- Flexbox: fixed-width icon column, text fills the rest.
      -- align-items: center vertically centers the icon relative to the
      -- text column so it sits at the middle of the callout.
      blocks:insert(pandoc.RawBlock("html",
        '<div style="' .. html_style ..
        ' display: flex; gap: 12px; align-items: center;">'))
      if single_page_callouts then
        -- Icon referenced by CSS class; the base64 data URI lives once in
        -- the <style> block injected by build-site.sh, not per callout.
        blocks:insert(pandoc.RawBlock("html",
          '<span class="callout-icon callout-' .. kind .. '" role="img" ' ..
          'aria-label="' .. kind .. '"></span>'))
      else
        blocks:insert(pandoc.RawBlock("html",
          '<img src="../images/' .. kind .. '-callout.png" ' ..
          'style="width: 48px; flex-shrink: 0;">'))
      end
      blocks:insert(pandoc.RawBlock("html",
        '<div style="flex: 1; min-width: 0;">'))
      for _, cb in ipairs(el.content) do
        blocks:insert(cb)
      end
      blocks:insert(pandoc.RawBlock("html", '</div></div>'))
    else
      blocks:insert(pandoc.RawBlock("html",
        '<div style="' .. html_style .. '">'))
      for _, cb in ipairs(el.content) do
        blocks:insert(cb)
      end
      blocks:insert(pandoc.RawBlock("html", '</div>'))
    end
    return blocks
  end
end

-- Two passes so Meta (which sets single_page_callouts) is guaranteed to
-- run before any Div is visited; pandoc's default bottom-up traversal
-- would call Div before Meta if they were in the same pass.
return {{Meta = Meta}, {Div = Div}}
