module selt.labeler;

import std.typecons, std.string;

class LabelException : Exception {
  this(string msg) {
    super(msg);
  }
}

Tuple!(string,string)[] label(string code) {
  Tuple!(string,string)[] result;
  string[] lines = code.splitLines();
  for(int i = 0; i < lines.length; i++) {
    string[] l = lines[i].split(":");
    if(l.length > 2) {
      throw new LabelException(format("Too many colons on line %d", i+1));
    }
    if(l.length == 2) {
      if(l[0].length > 0 && l[0][0] == '#') result ~= tuple("", ""); // ignore comments
      else {
        // remove any spaces or tabs from the start of the label
        // (there's probably a better way to do this but this works; regex maybe?)
        int j;
        for(j = 0; j < l[0].length; j++) {
          if(l[0][j] != ' ' && l[0][j] != '\t') break;
        }
        result ~= tuple(l[0][j..$], l[1]);
      }
    } else if(l.length == 1) {
      result ~= tuple("", l[0]);
    } else {
      result ~= tuple("", "");
    }
  }
  return result;
}