module selt.interpreter;

import std.typecons, std.stdio, std.string, std.conv;
import selt.node, selt.lexer, selt.parser;

class InterpreterException : Exception {
  int line;
  this(int line, string msg) {
    super(msg);
    this.line = line;
  }
}

void interpret(Tuple!(string, string)[] program, bool[string] flags) {
  if(flags["lex"]) {
    for(int i = 0; i < program.length; i++) {
      string label = program[i][0];
      string code = program[i][1];
      Lexeme[] lexemes = lex(code);
      writeln(label~": "~nodeArrayToString(cast(Node[])lexemes));
    }
  } else if(flags["parse"]) {
    for(int i = 0; i < program.length; i++) {
      string label = program[i][0];
      string code = program[i][1];
      Lexeme[] lexemes = lex(code);
      Node[] nodes = parse(lexemes);
      writeln(label~": "~nodeArrayToString(nodes));
    }
  } else {
    int[] stack;
    loop:
    for(int i = 0; i < program.length; i++) {
      bool truthy(string s) {
        return s == "1";
      }
      int findLabel(string s) {
        for(int j = 0; j < program.length; j++) {
          if(program[j][0] == s) {
            return j;
          }
        }
        throw new InterpreterException(i+1, format("Unknown label %s", s));
      }
      int num(string s) {
        try {
          return to!int(s);
        } catch(ConvException e) {
          throw new InterpreterException(i+1, format("%s is not an integer", s));
        }
      }
      string valueOf(Node n) {
        if(Lexeme l = cast(Lexeme)n) {
          if(l.type == Ltype.TERM) {
            return l.value;
          } else {
            throw new InterpreterException(i+1, format("Unexpected lexeme %s", l));
          }
        } else if(Expression e = cast(Expression)n) {
          final switch(e.type) {
            case Etype.BIN: {
              Lexeme op = cast(Lexeme)e.contents[1];
              string left = valueOf(e.contents[0]);
              string right = valueOf(e.contents[2]);
              switch(op.type) {
                default:
                  return ""; // unreachable but compiler doesn't know that (or really can't)
                case Ltype.ADD:
                  return to!string(num(left) + num(right));
                case Ltype.SUB:
                  return to!string(num(left) - num(right));
                case Ltype.MUL:
                  return to!string(num(left) * num(right));
                case Ltype.DIV:
                  return to!string(num(left) / num(right));
                case Ltype.MOD:
                  return to!string(num(left) % num(right));
                case Ltype.CON:
                  return left~right;
                case Ltype.INDEX: {
                  int idx = num(right);
                  if(idx < 0 || idx >= left.length) {
                    throw new InterpreterException(i+1, format("Index %s out of bounds", idx));
                  }
                  return to!string(left[idx]);
                }
                case Ltype.EQ:
                  return left == right ? "1" : "0";
                case Ltype.NE:
                  return left != right ? "1" : "0";
                case Ltype.LT:
                  return num(left) < num(right) ? "1" : "0";
                case Ltype.GT:
                  return num(left) > num(right) ? "1" : "0";
                case Ltype.LE:
                  return num(left) <= num(right) ? "1" : "0";
                case Ltype.GE:
                  return num(left) >= num(right) ? "1" : "0";
                case Ltype.AND:
                  return truthy(left) && truthy(right) ? "1" : "0";
                case Ltype.OR:
                  return truthy(left) || truthy(right) ? "1" : "0";
              }
            }
            case Etype.UN: {
              Lexeme op = cast(Lexeme)e.contents[0];
              string arg = valueOf(e.contents[1]);
              switch(op.type) {
                default:
                  return "";
                case Ltype.NOT:
                  return truthy(arg) ? "0" : "1";
                case Ltype.AT:
                  if(arg == "stdin") return readln()[0..$-1]; // remove newline
                  return program[findLabel(arg)][1];
                case Ltype.LINE:
                  return to!string(findLabel(arg)+1);
                case Ltype.DELINE: {
                  int line = num(arg);
                  if(line > 0 && line <= program.length) {
                    return program[line-1][1];
                  } else {
                    throw new InterpreterException(i+1, format("Line %d is out of bounds", line));
                  }
                }
                case Ltype.LENGTH:
                  return to!string(arg.length);
              }
            }
          }
        } else {
          throw new InterpreterException(i+1, format("Unexpected node %s", n));
        }
      }
      string label = program[i][0];
      string code = program[i][1];
      Lexeme[] lexemes = lex(code);
      Node[] nodes = parse(lexemes);
      if(nodes.length > 1) {
        throw new InterpreterException(i+1, format("Unexpected node %s", nodes[1]));
      } else {
        if(Statement s = cast(Statement)nodes[0]) {
          final switch(s.type) {
            case Stype.PRINT:
              write(valueOf(s.contents[0]));
              break;
            case Stype.PRINTLN:
              writeln(valueOf(s.contents[0]));
              break;
            case Stype.GOTO:
              i = findLabel(valueOf(s.contents[0]))-1;
              break;
            case Stype.CALL:
              stack ~= i;
              i = findLabel(valueOf(s.contents[0]))-1;
              break;
            case Stype.RETURN:
              if(stack.length > 0) {
                i = stack[$-1];
                stack = stack[0..$-1];
              } else {
                break loop;
              }
              break;
            case Stype.ASSIGN: {
              int l = findLabel(valueOf(s.contents[0]));
              string value = valueOf(s.contents[1]);
              program[l][1] = value;
              break;
            }
            case Stype.NOP:
              break;
          }
        } else {
          throw new InterpreterException(i+1, format("Unexpected node %s", nodes[0]));
        }
      }
    }
  }
}