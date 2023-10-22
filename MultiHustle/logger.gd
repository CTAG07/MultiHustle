extends Node

const file_path = "user://logs/mhlogs.log"

static func mh_log(message: String, clear = false):
  var file = File.new()
  var result = file.open(file_path, File.READ_WRITE)
  if result != OK or clear:
    file.open(file_path, File.WRITE_READ)
  var text = file.get_as_text()
  file.store_string(text + "[Multihustle] " + message + "\n")
  file.close()