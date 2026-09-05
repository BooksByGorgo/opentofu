-- Session filter: renders ```session code blocks as a terminal session.
-- Lines that start with "$ " are what you type and come out bold; every
-- other line is what the tool printed. The block is drawn as an outlined,
-- shaded box so it reads differently from a configuration listing, which
-- pandoc renders with its usual shading and no frame.
--
-- LaTeX: a breakable tcolorbox around a fancyvrb Verbatim environment, so
-- a long session can cross a page boundary. commandchars lets \textbf{}
-- through, which means backslashes and braces in the text must be escaped.
-- HTML: a <pre class="session"> with inline styles and <b> around commands.

local tcb = "colback=black!4, colframe=black!45, boxrule=0.6pt, arc=2pt, " ..
  "left=4pt, right=4pt, top=2pt, bottom=2pt, breakable"

local html_style = "background-color: #f4f4f4; border: 1px solid #999; " ..
  "border-radius: 4px; padding: 8px 12px; margin: 1em 0; overflow-x: auto;"

local function tex_escape(s)
  return (s:gsub("[\\{}]", {
    ["\\"] = "\\textbackslash{}",
    ["{"] = "\\{",
    ["}"] = "\\}",
  }))
end

local function html_escape(s)
  return (s:gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

local function is_command(line)
  return line:sub(1, 2) == "$ "
end

function CodeBlock(el)
  if not el.classes:includes("session") then return nil end
  local fmt = FORMAT
  local lines = {}
  for line in (el.text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end

  if fmt:match("latex") then
    local out = {}
    for _, line in ipairs(lines) do
      if is_command(line) then
        table.insert(out, "\\textbf{" .. tex_escape(line) .. "}")
      else
        table.insert(out, tex_escape(line))
      end
    end
    return pandoc.RawBlock("latex",
      "\\begin{tcolorbox}[" .. tcb .. "]\n" ..
      "\\begin{Verbatim}[commandchars=\\\\\\{\\}]\n" ..
      table.concat(out, "\n") .. "\n" ..
      "\\end{Verbatim}\n" ..
      "\\end{tcolorbox}")

  elseif fmt:match("html") then
    local out = {}
    for _, line in ipairs(lines) do
      if is_command(line) then
        table.insert(out, "<b>" .. html_escape(line) .. "</b>")
      else
        table.insert(out, html_escape(line))
      end
    end
    return pandoc.RawBlock("html",
      '<pre class="session" style="' .. html_style .. '">' ..
      table.concat(out, "\n") .. "</pre>")
  end
end
