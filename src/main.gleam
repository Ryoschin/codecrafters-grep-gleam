import argv
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  // You can use print statements as follows for debugging, they'll be visible when running tests.
  // io.print_error("Logs from your program will appear here!")

  let args = argv.load().arguments
  let assert Ok(input_line) = erlang.get_line("")

  // Uncomment this to pass the first stage
  case args {
    ["-E", pattern, ..] -> {
      case match_pattern(input_line, pattern) {
        True -> exit(0)
        False -> exit(1)
      }
    }
    _ -> {
      io.println("Expected first argument to be '-E'")
      exit(1)
    }
  }
}

fn match_pattern(input_line: String, pattern: String) -> Bool {
  case string.starts_with(pattern, "[") {
    True -> {
      case string.split_once(string.drop_left(pattern, 1), "]") {
        Ok(pattern_list) -> {
          let #(pattern_chars, _) = pattern_list
          let #(source, check) = compare_str_len(pattern_chars, input_line)
          list.any(source, fn(c) { string.contains(check, c) })
        }
        Error(_) -> {
          io.println("Unhandled pattern: " <> pattern)
          False
        }
      }
    }

    False -> {
      case string.length(pattern) {
        1 -> string.contains(input_line, pattern)
        2 -> {
          case pattern {
            "\\d" -> contains_number(input_line)
            "\\w" -> is_alphanumeric(input_line)
            _ -> {
              io.println("Unhandled pattern: " <> pattern)
              False
            }
          }
        }
        _ -> {
          io.println("Unhandled pattern: " <> pattern)
          False
        }
      }
    }
  }
}

fn is_alphanumeric(str: String) -> Bool {
  let chars = string.to_graphemes(string.lowercase(str))
  list.any(chars, fn(c) { c == "_" || is_number(c) || is_az(c) })
}

fn contains_number(str: String) -> Bool {
  let chars = string.to_graphemes(str)
  list.any(chars, fn(c) { is_number(c) })
}

fn is_number(char: String) {
  case int.parse(char) {
    Ok(_) -> True
    _ -> False
  }
}

fn is_az(char: String) {
  let assert [a, ..] = string.to_utf_codepoints("a")
  let a = string.utf_codepoint_to_int(a)
  let assert [z, ..] = string.to_utf_codepoints("z")
  let z = string.utf_codepoint_to_int(z)
  let assert [c, ..] = string.to_utf_codepoints(char)
  let c = string.utf_codepoint_to_int(c)
  c >= a && c <= z
}

fn compare_str_len(str1: String, str2: String) -> #(List(String), String) {
  case string.length(str1) >= string.length(str2) {
    True -> {
      #(string.to_graphemes(str1), str2)
    }
    False -> {
      #(string.to_graphemes(str2), str1)
    }
  }
}

@external(erlang, "erlang", "halt")
pub fn exit(code: Int) -> Int
