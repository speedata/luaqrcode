#!/usr/bin/env lua


function err( ... )
	print(string.format(...))
end

local failed = false
function assert_equal( a,b,func )
	if a ~= b then
		err("Assertion failed: %s: %q is not equal to %q",func,tostring(a),tostring(b))
		failed = true
	end
end

testing=true


local qrcode        = dofile("qrencode.lua")
local tab
str = "HELLO WORLD"
assert_equal(qrcode.get_mode("0101"),           1,"get_encoding_byte 1")
assert_equal(qrcode.get_mode(str),              2,"get_encoding_byte 2")
assert_equal(qrcode.get_mode("0-9A-Z $%*./:+-"),2,"get_encoding_byte 3")
assert_equal(qrcode.get_mode("foär"),           4,"get_encoding_byte 4")
assert_equal(qrcode.get_length(str,1,2),"000001011","get_length")
assert_equal(qrcode.binary(5,10),"0000000101","binary()")
assert_equal(qrcode.binary(779,11),"01100001011","binary()")
assert_equal(qrcode.add_pad_data(1,3,"0010101"),"00101010000000001110110000010001111011000001000111101100000100011110110000010001111011000001000111101100","pad_data")

tab = qrcode.get_generator_polynominal_adjusted(13,25)
assert_equal(tab[1],0,"get_generator_polynominal_adjusted 0")
assert_equal(tab[24],74,"get_generator_polynominal_adjusted 24")
assert_equal(tab[25],0,"get_generator_polynominal_adjusted 25")
tab = qrcode.get_generator_polynominal_adjusted(13,24)
assert_equal(tab[1],0,"get_generator_polynominal_adjusted 0")
assert_equal(tab[23],74,"get_generator_polynominal_adjusted 23")
assert_equal(tab[24],0,"get_generator_polynominal_adjusted 24")

tab = qrcode.convert_bitstring_to_bytes("00100000010110110000101101111000110100010111001011011100010011010100001101000000111011000001000111101100")
assert_equal(tab[1],32,"convert_bitstring_to_bytes")
assert_equal(qrcode.bit_xor(141,43), 166,"bit_xor")
assert_equal(qrcode.bit_xor(179,0), 179,"bit_xor")

-- local hello_world_msg_with_ec = "0010000001011011000010110111100011010001011100101101110001001101010000110100000011101100000100011110110010101000010010000001011001010010110110010011011010011100000000000010111000001111101101000111101000010000"

assert_equal(qrcode.get_pixel_with_mask(0,21,21,1),-1,"get_pixel_with_mask 1")
assert_equal(qrcode.get_pixel_with_mask(0,1,1,1),-1,"get_pixel_with_mask 2")
local a,b,c,d,e = qrcode.get_version_eclevel_mode_bistringlength(str)
assert_equal(a,1,"get_version_eclevel_mode_bistringlength 1")
assert_equal(b,3,"get_version_eclevel_mode_bistringlength 2")
assert_equal(c,"0010","get_version_eclevel_mode_bistringlength 3")
assert_equal(d,2,"get_version_eclevel_mode_bistringlength 4")
assert_equal(e,"000001011","get_version_eclevel_mode_bistringlength 5")

assert_equal(qrcode.encode_string_numeric("01234567"),"000000110001010110011000011","encode string numeric")
assert_equal(qrcode.encode_string_ascii(str),"0110000101101111000110100010111001011011100010011010100001101","encode string ascii")
assert_equal(qrcode.remainder[40],0,"get_remainder")
assert_equal(qrcode.remainder[2],7,"get_remainder")


-------------------
-- Error correction
-------------------
local data = {32, 234, 187, 136, 103, 116, 252, 228, 127, 141, 73, 236, 12, 206, 138, 7, 230, 101, 30, 91, 152, 80, 0, 236, 17, 236, 17, 236}
local ec_expected = {73, 31, 138, 44, 37, 176, 170, 36, 254, 246, 191, 187, 13, 137, 84, 63}
local ec = qrcode.calculate_error_correction(data,16)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {32, 234, 187, 136, 103, 116, 252, 228, 127, 141, 73, 236, 12, 206, 138, 7, 230, 101, 30, 91, 152, 80, 0, 236, 17, 236, 17, 236, 17, 236, 17, 236, 17, 236}
ec_expected = {66, 146, 126, 122, 79, 146, 2, 105, 180, 35}
local ec = qrcode.calculate_error_correction(data,10)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {32, 83, 7, 120, 209, 114, 215, 60, 224}
ec_expected = {123, 120, 222, 125, 116, 92, 144, 245, 58, 73, 104, 30, 108, 0, 30, 166, 152}
local ec = qrcode.calculate_error_correction(data,17)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {32,83,7,120,209,114,215,60,224,236,17}
ec_expected = {3, 67, 244, 57, 183, 14, 171, 101, 213, 52, 148, 3, 144, 148, 6, 155, 3, 252, 228, 100, 11, 56}
local ec = qrcode.calculate_error_correction(data,22)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {236,17,236,17,236, 17,236, 17,236, 17,236}
ec_expected = {171, 165, 230, 109, 241, 45, 198, 125, 213, 84, 88, 187, 89, 61, 220, 255, 150, 75, 113, 77, 147, 164}
local ec = qrcode.calculate_error_correction(data,22)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {17,236, 17,236, 17,236,17,236, 17,236, 17,236}
ec_expected = {23, 115, 68, 245, 125, 66, 203, 235, 85, 88, 174, 178, 229, 181, 118, 148, 44, 175, 213, 243, 27, 215}
local ec = qrcode.calculate_error_correction(data,22)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end

-- "HALLO WELT" in alphanumeric, code 5-H
data = { 32,83,7,120,209,114,215,60,224,236,17,236,17,236,17,236, 17,236, 17,236, 17,236, 17, 236, 17,236, 17,236, 17,236, 17,236, 17,236, 17, 236, 17,236, 17,236, 17,236, 17,236, 17,236}
message_expected = {32, 236, 17, 17, 83, 17, 236, 236, 7, 236, 17, 17, 120, 17, 236, 236, 209, 236, 17, 17, 114, 17, 236, 236, 215, 236, 17, 17, 60, 17, 236, 236, 224, 236, 17, 17, 236, 17, 236, 236, 17, 236, 17, 17, 236, 236, 3, 171, 23, 23, 67, 165, 115, 115, 244, 230, 68, 68, 57, 109, 245, 245, 183, 241, 125, 125, 14, 45, 66, 66, 171, 198, 203, 203, 101, 125, 235, 235, 213, 213, 85, 85, 52, 84, 88, 88, 148, 88, 174, 174, 3, 187, 178, 178, 144, 89, 229, 229, 148, 61, 181, 181, 6, 220, 118, 118, 155, 255, 148, 148, 3, 150, 44, 44, 252, 75, 175, 175, 228, 113, 213, 213, 100, 77, 243, 243, 11, 147, 27, 27, 56, 164, 215, 215}
tmp = qrcode.arrange_codewords_and_calculate_ec(5,4,data)
message = qrcode.convert_bitstring_to_bytes(tmp)
for i=1,#message do
	assert_equal(message_expected[i],message[i],string.format("arrange_codewords_and_calculate_ec %d",i))
end

print("Tests end here")
if failed then
	print("Some tests failed, see above")
else
	print("Everything looks fine")
end
