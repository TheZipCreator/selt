module zip.simpleoptions;

import std.algorithm;
import std.stdio;

class SimpleOptions {
  string[][string] inputs;
  bool[string] flags;

  this(string[] args, string[] inputList, string[] flagList) {
    // args is commandline arguments
    // inputList is a list of inputs beginning with - (example would be ["-i", "-output", "-header"])
    // flagList is a list of flags beginning with -- (example would be ["--verbose", "--help"])

    // initialize inputs and flags

    foreach(string s; inputList) {
      inputs[s] = [];
    }
    inputs[""] = []; // any given argument that is not in an input is in ""

    foreach(string s; flagList) {
      flags[s] = false;
    }

    // parse args

    for(int i = 1; i < args.length; i++) {
      string a = args[i];
      // inputs
      if(a.startsWith("-") && a.length > 1 && a[1] != '-') {
        a = a[1..$];
        if(inputList.canFind(a)) {
          if(i+1 < args.length) {
            inputs[a] ~= args[i+1];
            i++;
            continue;
          } else {
            throw new SimpleOptionsException("Missing argument for input -"~a);
          }
        } else {
          throw new SimpleOptionsException("Unknown input -"~a);
        }
      }
      // flags
      else if(a.startsWith("--")) {
        a = a[2..$];
        if(flagList.canFind(a)) {
          flags[a] = true;
          continue;
        }
      } else {
        inputs[""] ~= a;
      }
    }
  }

  unittest {
    string[] args = ["-i", "test.txt", "-i", "abc.txt", "-output", "out.a", "--verbose", "--help", "test"];
    string[] inputList = ["-i", "-output"];
    string[] flagList = ["--verbose", "--help", "--test"];
    SimpleOptions so = new SimpleOptions(args, inputList, flagList);
    assert(so.inputs[""].length == 1);
    assert(so.inputs[""][0] == "test");
    assert(so.inputs["i"].length == 2);
    assert(so.inputs["i"][0] == "test.txt");
    assert(so.inputs["i"][1] == "abc.txt");
    assert(so.inputs["output"].length == 1);
    assert(so.inputs["output"][0] == "out.a");
    assert(so.flags["verbose"]);
    assert(so.flags["help"]);
    assert(!so.flags["test"]);

  }
}

class SimpleOptionsException : Exception {
  this(string message) {
    super(message);
  }
}