std = "max"
include_files = {
  "**/*.lua",
  "*.rockspec",
  ".luacheckrc"
}
exclude_files = {
  ".luarocks",
  "locco/*"
}
globals = {
  "testing",
  "debugging"
}
max_line_length = false
