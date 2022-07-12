module selt.app;

import std.stdio, std.file, std.typecons, std.string;
import selt.labeler, selt.interpreter;
import zip.simpleoptions;

int main(string[] args) {
  SimpleOptions so = new SimpleOptions(args, [], ["help", "version", "label", "lex", "parse"]);
  if(so.flags["help"]) {
    writeln("Flags:");
    writeln("  --help:    show this help");
    writeln("  --version: show version");
    writeln("  --label:   label the input");
    writeln("  --lex:     lex the input");
    writeln("  --parse:   parse the input");
    return 0;
  }
  if(so.flags["version"]) {
    writeln("Selt Interpreter v1.0");
    return 0;
  }
  string[] inputs = so.inputs[""];
  if(inputs.length == 0) {
    writeln("Fatal error: no input files");
    return 1;
  }
  foreach(string input; inputs) {
    try {
      string code = readText(input);
      try {
        Tuple!(string,string)[] labels = label(code);
        if(so.flags["label"]) {
          writeln("Label:\tCode:");
          foreach(Tuple!(string,string) label; labels) {
            writeln(label[0]~"\t"~label[1]);
          }
        }
        interpret(labels, so.flags);
      } catch(LabelException e) {
        writeln(e.message);
        return 1;
      } catch(InterpreterException e) {
        writeln(format("Line %d: %s", e.line, e.message));
        return 1;
      }
    } catch(FileException e) {
      writeln("Fatal error: "~e.message);
      return 1;
    }
  }
  return 0;
}