extends Node

const file_path = "user://logs/mhlogs.log"

static func mh_log(message: String):
  var file = File.new()
  var result = file.open(file_path, File.READ_WRITE)
  if result != OK:
    print("Error opening file: " + str(result))
  else:
    var text = file.get_as_text()
    file.store_string(text + "[Multihustle] " + message + "\n")
    file.close()