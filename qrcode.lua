#!/usr/bin/env lua


qrencode = dofile("qrencode.lua")

-- Return string representation of the qr code matrix
local function matrix_to_string( tab )
  -- Add one row at the top and at the bottom
  str_tab = {}
  for i=1,#tab + 2 do
    str_tab[i] = "\27[1;47m  \27[0m"
  end
  for x=1,#tab do
     -- str_tab[x] = str_tab[x] .. "X"
    for y=1,#tab do
      if tab[x][y] > 0 then
        str_tab[y + 1] = str_tab[y + 1] .. "\27[40m  \27[0m"
      elseif tab[x][y] < 0 then
        str_tab[y + 1] = str_tab[y + 1] .. "\27[1;47m  \27[0m"
      else
        str_tab[y + 1] = str_tab[y + 1] .. " X"
      end
    end
  end
  str_tab[1] =  str_tab[1] .. string.rep("\27[1;47m  \27[0m",#tab)
  str_tab[#tab + 2] =  str_tab[#tab + 2] .. string.rep("\27[1;47m  \27[0m",#tab)
  for i=1,#tab + 2 do
    str_tab[i] = str_tab[i] .. "\27[1;47m  \27[0m"
  end

  return table.concat(str_tab,"\n")
end

if arg[1] then
	local ok, tab_or_message = qrencode.qrcode(arg[1])
	if not ok then
		print(tab_or_message)
	else
		print(matrix_to_string(tab_or_message))
	end
else
	print(arg[0] .. " <contents>")
end
