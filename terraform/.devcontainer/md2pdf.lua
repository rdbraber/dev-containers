-- Pandoc filter for md2pdf (commonmark_x input, Typst output):
-- - a level-1 heading becomes the document title when it is the first block or the only
--   level-1 heading; if it is the only one, the other headings move up one level
-- - relative links (to files in the repo) become plain text, since they can't resolve in a PDF
-- - GitHub alerts (> [!NOTE] etc.) become coloured boxes (alert() in md2pdf.typst)
-- - inline HTML <ins>/<u>, <sub>, <sup>, <mark> and <kbd> keep their formatting
-- - HTML blocks (<p>, <dl>, <details>/<summary>) are converted instead of dropped
-- - task lists get ☑/☐ boxes without bullets

local function typst(s) return pandoc.RawBlock('typst', s) end
local function typst_inline(s) return pandoc.RawInline('typst', s) end

-- Relative links

local function is_relative(target)
  return not target:match('^%a[%w+.-]*:') and not target:match('^#')
end

local function Link(el)
  if is_relative(el.target) then
    return el.content
  end
end

-- Inline HTML

local wrappers = {
  ins = function(c) return { pandoc.Underline(c) } end,
  u = function(c) return { pandoc.Underline(c) } end,
  sub = function(c) return { pandoc.Subscript(c) } end,
  sup = function(c) return { pandoc.Superscript(c) } end,
  mark = function(c) return { typst_inline('#highlight['), c, typst_inline(']') } end,
  kbd = function(c) return { typst_inline('#kbd['), c, typst_inline(']') } end,
}

local function html_tag(el)
  if el.t == 'RawInline' and el.format == 'html' then
    local close, name = el.text:match('^<(/?)(%a+)>$')
    if name and wrappers[name:lower()] then return name:lower(), close == '/' end
  end
end

local function Inlines(inlines)
  local out, i = pandoc.Inlines{}, 1
  while i <= #inlines do
    local name, closing = html_tag(inlines[i])
    local j
    if name and not closing then
      for k = i + 1, #inlines do
        local n, c = html_tag(inlines[k])
        if n == name and c then j = k; break end
      end
    end
    if j then
      local inner = pandoc.Inlines{}
      for k = i + 1, j - 1 do inner:insert(inlines[k]) end
      for _, x in ipairs(wrappers[name](inner)) do
        if x.t then out:insert(x) else out:extend(x) end
      end
      i = j + 1
    else
      out:insert(inlines[i])
      i = i + 1
    end
  end
  return out
end

-- Task lists

local function Str(el)
  if el.text == '☒' then return pandoc.Str('☑') end
end

local function is_task_list(list)
  for _, item in ipairs(list.content) do
    local first = item[1] and item[1].content and item[1].content[1]
    if not (first and first.t == 'Str' and (first.text == '☒' or first.text == '☑' or first.text == '☐')) then
      return false
    end
  end
  return true
end

local function BulletList(el)
  if is_task_list(el) then
    return { typst('#[#set list(marker: none)'), el, typst(']') }
  end
end

-- Alerts

local alert_kinds = { note = true, tip = true, important = true, warning = true, caution = true }

local function Div(el)
  local kind = el.classes[1]
  if not (kind and alert_kinds[kind]) then return nil end
  local title, body = kind:sub(1, 1):upper() .. kind:sub(2), pandoc.Blocks{}
  for _, b in ipairs(el.content) do
    if b.t == 'Div' and b.classes:includes('title') then
      title = pandoc.utils.stringify(b)
    else
      body:insert(b)
    end
  end
  local out = pandoc.Blocks{ typst(string.format('#alert("%s", "%s")[', kind, title)) }
  out:extend(body)
  out:insert(typst(']'))
  return out
end

-- HTML blocks

local function RawBlock(el)
  if el.format ~= 'html' then return nil end
  local summary = el.text:match('<summary>(.-)</summary>')
  if summary then
    return pandoc.Para{ pandoc.Strong(pandoc.utils.blocks_to_inlines(pandoc.read(summary, 'html').blocks)) }
  end
  local blocks = pandoc.read(el.text, 'html').blocks
  if el.text:match('^%s*<p[^>]-align="center"') then
    local out = pandoc.Blocks{ typst('#align(center)[') }
    out:extend(blocks)
    out:insert(typst(']'))
    return out
  end
  return blocks
end

-- Title

local function Pandoc(doc)
  if doc.meta.title then return doc end

  local h1s, idx = 0, nil
  for i, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 1 then
      h1s = h1s + 1
      idx = idx or i
    end
  end
  if not idx or (idx ~= 1 and h1s ~= 1) then return doc end

  doc.meta.title = doc.blocks[idx].content
  doc.blocks:remove(idx)
  if h1s == 1 then
    for _, b in ipairs(doc.blocks) do
      if b.t == 'Header' then b.level = b.level - 1 end
    end
  end
  return doc
end

return {
  { Inlines = Inlines },
  { Link = Link, Str = Str, BulletList = BulletList, Div = Div, RawBlock = RawBlock },
  { Pandoc = Pandoc },
}
