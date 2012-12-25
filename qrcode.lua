#!/usr/bin/env lua


qrencode = dofile("qrencode.lua")

local function matrix_to_string( tab )
  str_tab = {}
  for i=1,#tab do
    str_tab[i] = ""
  end
  for x=1,#tab do
    for y=1,#tab do
      if tab[x][y] > 0 then
        str_tab[y] = str_tab[y] .. "\27[40m  \27[0m"
      elseif tab[x][y] < 0 then
        str_tab[y] = str_tab[y] .. "\27[1;47m  \27[0m"
      else
        str_tab[y] = str_tab[y] .. " X"
      end
    end
  end
  return table.concat(str_tab,"\n")
end

if arg[1] then
	local ok, tab_or_message = qrcodelib.qrcode(arg[1])
	if not ok then
		print(tab_or_message)
	else
		print(matrix_to_string(tab_or_message))
	end
else
	print(arg[0] .. " <contents>")
end
