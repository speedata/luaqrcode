#!/usr/bin/env lua


local function err( ... )
	print(string.format(...))
end

local failed = false
local function assert_equal( a,b,func )
	if a ~= b then
		err("Assertion failed: %s: %q is not equal to %q",func,tostring(a),tostring(b))
		failed = true
	end
end

testing=true


local qrcode = dofile("qrencode.lua")
local tab
local str = "HELLO WORLD"
local almost_full_data = string.rep("1",70)
local hello_world_version, hello_world_ec, hello_world_mode, hello_world_modebits, hello_world_lenbits
local hello_world_arranged
local hello_world_penalty
local function new_matrix(size)
	local matrix = {}
	for i=1,size do
		matrix[i] = {}
		for j=1,size do
			matrix[i][j] = 0
		end
	end
	return matrix
end
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
tab = qrcode.convert_bitstring_to_bytes("1111111100000001")
assert_equal(tab[1],255,"convert_bitstring_to_bytes 2")
assert_equal(tab[2],1,"convert_bitstring_to_bytes 3")
assert_equal(qrcode.xor_lookup[141][43], 166,"xor_lookup")
assert_equal(qrcode.xor_lookup[179][0], 179,"xor_lookup")

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
assert_equal(qrcode.encode_string_numeric("987654321"),"111101101110100011100101000001","encode string numeric multi groups")
assert_equal(qrcode.encode_string_numeric("7"),"0111","encode string numeric single digit")
assert_equal(qrcode.encode_string_numeric("42"),"0101010","encode string numeric two digits")
assert_equal(qrcode.encode_string_ascii(str),"0110000101101111000110100010111001011011100010011010100001101","encode string ascii")
assert_equal(qrcode.encode_string_ascii("HELLO"),"0110000101101111000110011000","encode string ascii odd length")
assert_equal(qrcode.encode_string_ascii("AB"),"00111001101","encode string ascii even length")
assert_equal(qrcode.encode_string_ascii("A"),"001010","encode string ascii single character")
assert_equal(qrcode.encode_string_binary("Hi"),"0100100001101001","encode string binary")
assert_equal(qrcode.encode_data("123",1),"0001111011","encode data numeric mode")
assert_equal(qrcode.encode_data("HI",2),"01100001111","encode data ascii mode")
assert_equal(qrcode.encode_data("A",4),"01000001","encode data binary mode")
assert_equal(qrcode.add_pad_data(1,4,almost_full_data),almost_full_data .. "00","pad_data near capacity")
assert_equal(qrcode.remainder[40],0,"get_remainder")
assert_equal(qrcode.remainder[2],7,"get_remainder")

local matrix = new_matrix(21)
qrcode.fill_matrix_position(matrix,"1",5,5)
assert_equal(matrix[5][5],2,"fill_matrix_position black")
qrcode.fill_matrix_position(matrix,"0",5,6)
assert_equal(matrix[5][6],-2,"fill_matrix_position white")

matrix = new_matrix(21)
qrcode.add_position_detection_patterns(matrix)
assert_equal(matrix[1][1],2,"add_position_detection_patterns outer corner")
assert_equal(matrix[4][2],-2,"add_position_detection_patterns inner white ring")
assert_equal(matrix[3][3],2,"add_position_detection_patterns inner block")
assert_equal(matrix[21][7],2,"add_position_detection_patterns top right edge")
assert_equal(matrix[10][10],0,"add_position_detection_patterns untouched center")

qrcode.add_timing_pattern(matrix)
assert_equal(matrix[9][7],2,"add_timing_pattern vertical start")
assert_equal(matrix[10][7],-2,"add_timing_pattern vertical gap")
assert_equal(matrix[7][9],2,"add_timing_pattern horizontal start")
assert_equal(matrix[7][10],-2,"add_timing_pattern horizontal gap")
qrcode.add_typeinfo_to_matrix(matrix,1,0)
assert_equal(matrix[9][21],2,"add_typeinfo_to_matrix bottom first bit")
assert_equal(matrix[9][18],-2,"add_typeinfo_to_matrix bottom fourth bit")
assert_equal(matrix[9][6],-2,"add_typeinfo_to_matrix bottom tenth bit")
assert_equal(matrix[1][9],2,"add_typeinfo_to_matrix left first bit")
assert_equal(matrix[4][9],-2,"add_typeinfo_to_matrix left fourth bit")
assert_equal(matrix[21][9],-2,"add_typeinfo_to_matrix right last bit")

local matrix_v2 = new_matrix(25)
qrcode.add_position_detection_patterns(matrix_v2)
qrcode.add_timing_pattern(matrix_v2)
qrcode.add_alignment_pattern(matrix_v2)
assert_equal(matrix_v2[19][19],2,"add_alignment_pattern center")
assert_equal(matrix_v2[18][19],-2,"add_alignment_pattern inner ring vertical")
assert_equal(matrix_v2[19][18],-2,"add_alignment_pattern inner ring horizontal")
assert_equal(matrix_v2[17][19],2,"add_alignment_pattern outer ring vertical")
assert_equal(matrix_v2[21][21],2,"add_alignment_pattern outer ring diagonal")
assert_equal(matrix_v2[5][7],2,"add_alignment_pattern keep positioning pattern")

local matrix_v7 = new_matrix(45)
qrcode.add_version_information(matrix_v7,7)
assert_equal(matrix_v7[1][37],2,"add_version_information bottom left ones")
assert_equal(matrix_v7[5][35],2,"add_version_information bottom left center")
assert_equal(matrix_v7[37][1],2,"add_version_information top right ones")
assert_equal(matrix_v7[36][3],2,"add_version_information top right middle")
assert_equal(matrix_v7[35][1],-2,"add_version_information top right zeros")

local prepared_data = qrcode.prepare_matrix_with_mask(1,1,-1)
qrcode.add_data_to_matrix(prepared_data,"10101010",-1)
assert_equal(prepared_data[21][21],1,"add_data_to_matrix first bit")
assert_equal(prepared_data[20][21],-1,"add_data_to_matrix second bit")
assert_equal(prepared_data[21][20],1,"add_data_to_matrix third bit")
assert_equal(prepared_data[20][20],-1,"add_data_to_matrix fourth bit")

local prepared_masked = qrcode.prepare_matrix_with_mask(1,1,0)
qrcode.add_data_to_matrix(prepared_masked,"10101010",0)
assert_equal(qrcode.calculate_penalty(prepared_masked),567,"calculate_penalty sample")

hello_world_version, hello_world_ec, hello_world_modebits, hello_world_mode, hello_world_lenbits = qrcode.get_version_eclevel_mode_bistringlength(str)
hello_world_arranged = hello_world_modebits .. hello_world_lenbits .. qrcode.encode_data(str, hello_world_mode)
hello_world_arranged = qrcode.add_pad_data(hello_world_version,hello_world_ec,hello_world_arranged)
hello_world_arranged = qrcode.arrange_codewords_and_calculate_ec(hello_world_version,hello_world_ec,hello_world_arranged)
hello_world_arranged = hello_world_arranged .. string.rep("0", qrcode.remainder[hello_world_version])
tab, hello_world_penalty = qrcode.get_matrix_and_penalty(hello_world_version,hello_world_ec,hello_world_arranged,0)
assert_equal(#tab,21,"get_matrix_and_penalty size")
assert_equal(hello_world_penalty,344,"get_matrix_and_penalty penalty")


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
ec = qrcode.calculate_error_correction(data,10)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {32, 83, 7, 120, 209, 114, 215, 60, 224}
ec_expected = {123, 120, 222, 125, 116, 92, 144, 245, 58, 73, 104, 30, 108, 0, 30, 166, 152}
ec = qrcode.calculate_error_correction(data,17)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {32,83,7,120,209,114,215,60,224,236,17}
ec_expected = {3, 67, 244, 57, 183, 14, 171, 101, 213, 52, 148, 3, 144, 148, 6, 155, 3, 252, 228, 100, 11, 56}
ec = qrcode.calculate_error_correction(data,22)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {236,17,236,17,236, 17,236, 17,236, 17,236}
ec_expected = {171, 165, 230, 109, 241, 45, 198, 125, 213, 84, 88, 187, 89, 61, 220, 255, 150, 75, 113, 77, 147, 164}
ec = qrcode.calculate_error_correction(data,22)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {17,236, 17,236, 17,236,17,236, 17,236, 17,236}
ec_expected = {23, 115, 68, 245, 125, 66, 203, 235, 85, 88, 174, 178, 229, 181, 118, 148, 44, 175, 213, 243, 27, 215}
ec = qrcode.calculate_error_correction(data,22)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end
data = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
ec_expected = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
ec = qrcode.calculate_error_correction(data,10)
for i=1,#ec_expected do
	assert_equal(ec_expected[i],ec[i],string.format("calculate_error_correction %d",i))
end

-- "HALLO WELT" in alphanumeric, code 5-H
data = { 32,83,7,120,209,114,215,60,224,236,17,236,17,236,17,236, 17,236, 17,236, 17,236, 17, 236, 17,236, 17,236, 17,236, 17,236, 17,236, 17, 236, 17,236, 17,236, 17,236, 17,236, 17,236}
local message_expected = {32, 236, 17, 17, 83, 17, 236, 236, 7, 236, 17, 17, 120, 17, 236, 236, 209, 236, 17, 17, 114, 17, 236, 236, 215, 236, 17, 17, 60, 17, 236, 236, 224, 236, 17, 17, 236, 17, 236, 236, 17, 236, 17, 17, 236, 236, 3, 171, 23, 23, 67, 165, 115, 115, 244, 230, 68, 68, 57, 109, 245, 245, 183, 241, 125, 125, 14, 45, 66, 66, 171, 198, 203, 203, 101, 125, 235, 235, 213, 213, 85, 85, 52, 84, 88, 88, 148, 88, 174, 174, 3, 187, 178, 178, 144, 89, 229, 229, 148, 61, 181, 181, 6, 220, 118, 118, 155, 255, 148, 148, 3, 150, 44, 44, 252, 75, 175, 175, 228, 113, 213, 213, 100, 77, 243, 243, 11, 147, 27, 27, 56, 164, 215, 215}
local tmp = qrcode.arrange_codewords_and_calculate_ec(5,4,data)
local message = qrcode.convert_bitstring_to_bytes(tmp)
for i=1,#message do
	assert_equal(message_expected[i],message[i],string.format("arrange_codewords_and_calculate_ec %d",i))
end

print("Tests end here")
if failed then
	print("Some tests failed, see above")
else
	print("Everything looks fine")
end
os.exit(failed and 1 or 0)
