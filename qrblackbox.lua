#!/usr/bin/env lua

-- Black-box tests for qrencode.qrcode.
-- Test data lives in qrblackbox_data.lua; each sample is kept on a single line
-- to make appending new cases straightforward.

local qrencode = dofile("qrencode.lua")
local samples = dofile("qrblackbox_data.lua")

local failed = false

local function err(fmt, ...)
	print(string.format(fmt, ...))
end

local function assert_equal(a, b, label)
	if a ~= b then
		err("Assertion failed: %s: %q ~= %q", label, tostring(a), tostring(b))
		failed = true
	end
end

local function flatten_matrix(tab)
	local rows = {}
	local size = #tab
	for y = 1, size do
		local row = {}
		for x = 1, size do
			row[#row + 1] = tab[x][y] > 0 and "1" or "0"
		end
		rows[#rows + 1] = table.concat(row)
	end
	return rows
end

local function generate_test(input)
	local ok, matrix_or_msg = qrencode.qrcode(input)
	if not ok then
		return nil, matrix_or_msg
	end

	local rows = flatten_matrix(matrix_or_msg)
	local quoted_rows = {}
	for i = 1, #rows do
		quoted_rows[i] = string.format("%q", rows[i])
	end

	local line = string.format('{input=%q,rows={%s}},', input, table.concat(quoted_rows, ","))
	return line, rows
end

local function run_samples(data)
	failed = false

	for idx, sample in ipairs(data) do
		local ok, tab_or_msg = qrencode.qrcode(sample.input)
		assert_equal(ok, true, string.format("sample %d: qrcode success", idx))
		if ok then
			local rows = flatten_matrix(tab_or_msg)
			for i = 1, #sample.rows do
				assert_equal(rows[i], sample.rows[i], string.format("sample %d row %d", idx, i))
			end
		end
	end

	return not failed
end

local function usage(prog)
	err("Usage: %s [--generate <text>]", prog)
	err("  Without flags, runs black-box QR tests using qrblackbox_data.lua")
	err("  --generate <text>  prints a one-line sample you can paste into qrblackbox_data.lua")
end

if arg[1] == "--generate" then
	local input = arg[2]
	if not input then
		usage(arg[0] or "qrblackbox.lua")
		os.exit(1)
	end

	local line, err_or_rows = generate_test(input)
	if not line then
		err("Could not generate QR for %q: %s", input, tostring(err_or_rows))
		os.exit(1)
	end
	print(line)
	os.exit(0)
elseif arg[1] == "--help" then
	usage(arg[0] or "qrblackbox.lua")
	os.exit(0)
end

local ok = run_samples(samples)
if ok then
	print("Black-box QR tests passed")
	os.exit(0)
else
	print("Black-box QR tests failed")
	os.exit(1)
end
