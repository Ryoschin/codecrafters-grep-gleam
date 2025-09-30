import argv
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
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
          let #(check, _) = pattern_list
          let res = result.unwrap(string.split_once(check, "^"), #("^", check))
          let #(chars, source) = #(string.to_graphemes(res.1), input_line)

          case res.0 != "^" {
            True -> {
              list.any(chars, fn(c) { !string.contains(source, c) })
            }
            False -> {
              list.any(chars, fn(c) { string.contains(source, c) })
            }
          }
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

@external(erlang, "erlang", "halt")
pub fn exit(code: Int) -> Int
