--[==[

LUA MODULE
 
  luabalanced v$(_VERSION) - Functions for matching delimited snippets of Lua code in a string
  
SYNOPSIS

  local LB = require "luabalanced"
  -- Extract Lua expression starting at position 4.
  print(LB.match_expression("if x^2 + x > 5 then print(x) end", 4))
  --> x^2 + x > 5     16
  -- Extract Lua string starting at (default) position 1.
  print(LB.match_string([["test\"123" .. "more"]]))
  --> "test\"123"     12
  -- Break Lua code into code types.
  LB.gsub([[
    local x = 1  -- test
    print("x=", x)
  ]], function(u, s)
    print(u .. '[' .. s .. ']')
  end)
  --[[output:
  e[  local x = 1  ]
  c[-- test
  ]
  e[  print(]
  s["x="]
  e[, x)
  ]
  ]]

DESCRIPTION
  
  This module can, for example, match a Lua string, Lua comment, or Lua
  expression. It is useful in particular for source filters or parsing
  Lua snippets embedded in another language. It is inspired by Damian Conway's
  Text::Balanced [1] in Perl. The unique feature of this implementation
  is that that it does not rigorously lex and parse the Lua grammar.
  It doesn't need to. It assumes during the parse that the Lua code is
  syntactically correct (which can be verified later using loadstring).
  By assuming this, extraction of delimited sequences is significantly
  simplified yet can still be robust, and it also supports supersets
  of the Lua grammar. The code, which is written entirely in Lua,
  is just under 200 lines of Lua code (compare to Yueliang used in
  MetaLua, where the lexer alone is a few hundred lines).

API

  LB.match_string(s, pos) --> string, posnew
  
    Match Lua string in string <s> starting at position `pos`.
    Returns `string`, `posnew`, where `string` is the matched
    string (or nil on no match) and `posnew` is the character
    following the match (or `pos` on no match).
    Supports all Lua string syntax: "...", '...', [[...]], [=[...]=], etc.

  LB.match_bracketed(s, pos) --> string, posnew

    Match bracketed Lua expression, e.g. "(...)", "{...}", "[...]", "[[...]]",
    [=[...]=], etc.
    Function interface is similar to `match_string`.
    
  LB.match_comment(s, pos) --> string, posnew
  
    Match Lua comment, e.g. "--...\n", "--[[...]]", "--[=[...]=]", etc.
    Function interface is similar to `match_string`.

  LB.match_expression(s, pos) --> string, posnew
    
    Match Lua expression, e.g. "a + b * c[e]".
    Function interface is similar to match_string.

  LB.match_namelist(s, pos) --> array, posnew
  
    Match name list (zero or more names).  E.g. "a,b,c"
    Function interface is similar to match_string,
    but returns array as match.

  M.match_explist(s, pos) --> array, posnew
    
    Match expression list (zero or more expressions).  E.g. "a+b,b*c".
    Function interface is similar to match_string,
    but returns array as match.

  M.gsub(s, f)
  
    Replace snippets of code in Lua code string `s`
    using replacement function `f(u,sin) --> sout`.
    `u` is the type of snippet ('c' = comment, 's' = string,
    'e' = any other code).
    Snippet is replaced with `sout` (unless `sout` is `nil` or `false`, in
    which case the original snippet is kept)
    This is somewhat analogous to `string.gsub`.
    
DEPENDENCIES

  None (other than Lua 5.1 or 5.2).
  
HOME PAGE

  http://lua-users.org/wiki/LuaBalanced
  https://github.com/davidm/lua-balanced

DOWNLOAD/INSTALL

  If using LuaRocks:
    luarocks install lua-balanced

  Otherwise, download <https://github.com/davidm/lua-balanced/zipball/master>
  and unzip. Alternately, if using git:
    git clone git://github.com/davidm/lua-balanced.git
    cd lua-balanced
  Optionally unpack:
    ./util.mk
  or unpack and install in LuaRocks:
    ./util.mk install 
  
REFERENCES

  [1] http://lua-users.org/wiki/LuaBalanced
  [2] http://search.cpan.org/dist/Text-Balanced/lib/Text/Balanced.pm

 LICENSE

  (c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  (end license)

--]==]---------------------------------------------------------------------

local M = {_TYPE='module', _NAME='luabalanaced', _VERSION='0.1.1.20120323'}

local assert = assert

-- map opening brace <-> closing brace.
local ends = { ['('] = ')', ['{'] = '}', ['['] = ']' }
local begins = {}; for k,v in pairs(ends) do begins[v] = k end


local function match_string(s, pos)
  pos = pos or 1
  local posa = pos
  local c = s:sub(pos,pos)
  if c == '"' or c == "'" then
    pos = pos + 1
    while 1 do
      pos = assert(s:find("[" .. c .. "\\]", pos), 'syntax error')
      if s:sub(pos,pos) == c then
        local part = s:sub(posa, pos)
        return part, pos + 1
      else
        pos = pos + 2
      end
    end
  else
    local sc = s:match("^%[(=*)%[", pos)
    if sc then
      local _; _, pos = s:find("%]" .. sc .. "%]", pos)
      assert(pos)
      local part = s:sub(posa, pos)
      return part, pos + 1
    else
      return nil, pos
    end
  end
end
M.match_string = match_string


local function match_bracketed(s, pos)
  pos = pos or 1
  local posa = pos
  local ca = s:sub(pos,pos)
  if not ends[ca] then
    return nil, pos
  end
  local stack = {}
  while 1 do
    pos = s:find('[%(%{%[%)%}%]\"\']', pos)
    assert(pos, 'syntax error: unbalanced')
    local c = s:sub(pos,pos)
    if c == '"' or c == "'" then
      local part; part, pos = match_string(s, pos)
      assert(part)
    elseif ends[c] then -- open
      local mid, posb
      if c == '[' then mid, posb = s:match('^%[(=*)%[()', pos) end
      if mid then
        pos = s:match('%]' .. mid .. '%]()', posb)
        assert(pos, 'syntax error: long string not terminated')
        if #stack == 0 then
          local part = s:sub(posa, pos-1)
          return part, pos
        end
      else
        stack[#stack+1] = c
        pos = pos + 1
      end
    else -- close
      assert(stack[#stack] == assert(begins[c]), 'syntax error: unbalanced')
      stack[#stack] = nil
      if #stack == 0 then
        local part = s:sub(posa, pos)
        return part, pos+1
      end
      pos = pos + 1
    end
  end
end
M.match_bracketed = match_bracketed


local function match_comment(s, pos)
  pos = pos or 1
  if s:sub(pos, pos+1) ~= '--' then
    return nil, pos
  end
  pos = pos + 2
  local partt, post = match_string(s, pos)
  if partt then
    return '--' .. partt, post
  end
  local part; part, pos = s:match('^([^\n]*\n?)()', pos)
  return '--' .. part, pos
end


local wordop = {['and']=true, ['or']=true, ['not']=true}
local is_compare = {['>']=true, ['<']=true, ['~']=true}
local function match_expression(s, pos)
  pos = pos or 1
  local posa = pos
  local lastident
  local poscs, posce
  while pos do
    local c = s:sub(pos,pos)
    if c == '"' or c == "'" or c == '[' and s:find('^[=%[]', pos+1) then
      local part; part, pos = match_string(s, pos)
      assert(part, 'syntax error')
    elseif c == '-' and s:sub(pos+1,pos+1) == '-' then
      -- note: handle adjacent comments in loop to properly support
      -- backtracing (poscs/posce).
      poscs = pos
      while s:sub(pos,pos+1) == '--' do
        local part; part, pos = match_comment(s, pos)
        assert(part)
        pos = s:match('^%s*()', pos)
        posce = pos
      end
    elseif c == '(' or c == '{' or c == '[' then
      local part; part, pos = match_bracketed(s, pos)
    elseif c == '=' and s:sub(pos+1,pos+1) == '=' then
      pos = pos + 2  -- skip over two-char op containing '='
    elseif c == '=' and is_compare[s:sub(pos-1,pos-1)] then
      pos = pos + 1  -- skip over two-char op containing '='
    elseif c:match'^[%)%}%];,=]' then
      local part = s:sub(posa, pos-1)
      return part, pos
    elseif c:match'^[%w_]' then
      local newident,newpos = s:match('^([%w_]+)()', pos)
      if pos ~= posa and not wordop[newident] then -- non-first ident
        local pose = ((posce == pos) and poscs or pos) - 1
        while s:match('^%s', pose) do pose = pose - 1 end
        local ce = s:sub(pose,pose)
        if ce:match'[%)%}\'\"%]]' or
           ce:match'[%w_]' and not wordop[lastident]
        then
          local part = s:sub(posa, pos-1)
          return part, pos
        end
      end
      lastident, pos = newident, newpos
    else
      pos = pos + 1
    end
    pos = s:find('[%(%{%[%)%}%]\"\';,=%w_%-]', pos)
  end
  local part = s:sub(posa, #s)
  return part, #s+1
end
M.match_expression = match_expression


local function match_namelist(s, pos)
  pos = pos or 1
  local list = {}
  while 1 do
    local c = #list == 0 and '^' or '^%s*,%s*'
    local item, post = s:match(c .. '([%a_][%w_]*)%s*()', pos)
    if item then pos = post else break end
    list[#list+1] = item
  end
  return list, pos
end
M.match_namelist = match_namelist


local function match_explist(s, pos)
  pos = pos or 1
  local list = {}
  while 1 do
    if #list ~= 0 then
      local post = s:match('^%s*,%s*()', pos)
      if post then pos = post else break end
    end
    local item; item, pos = match_expression(s, pos)
    assert(item, 'syntax error')
    list[#list+1] = item
  end
  return list, pos
end
M.match_explist = match_explist


local function gsub(s, f)
  local pos = 1
  local posa = 1
  local ts = {}
  while 1 do
    pos = s:find('[%-\'\"%[]', pos)
    if not pos then break end
    if s:match('^%-%-', pos) then
      local exp = s:sub(posa, pos-1)
      if #exp > 0 then ts[#ts+1] = (f('e', exp) or exp) end
      local comment; comment, pos = match_comment(s, pos)
      ts[#ts+1] = (f('c', assert(comment)) or comment)
      posa = pos
    else
      local posb = s:find('^[\'\"%[]', pos)
      local str
      if posb then str, pos = match_string(s, posb) end
      if str then
        local exp = s:sub(posa, posb-1)
        if #exp > 0 then ts[#ts+1] = (f('e', exp) or exp) end
        ts[#ts+1] = (f('s', str) or str)
        posa = pos
      else
        pos = pos + 1
      end
    end
  end
  local exp = s:sub(posa)
  if #exp > 0 then ts[#ts+1] = (f('e', exp) or exp) end
  return table.concat(ts)
end
M.gsub = gsub


return M
