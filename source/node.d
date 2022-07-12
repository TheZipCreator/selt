module selt.node;

import std.string;

interface Node {
  string toString();
  string name();
}

string nodeArrayToString(Node[] nodes) {
  string s = "";
  for (int i = 0; i < nodes.length; i++) {
    if(i > 0) s ~= " ";
    s ~= nodes[i].toString();
  }
  return s;
}

class Lexeme : Node {
  enum LexemeType {
    TERM,
    ADD, SUB, MUL, DIV, MOD, CON, // + - * / % ~
    AT, LINE, DELINE, INDEX, LENGTH, // @ & | . ?
    EQ, NE, LT, LE, GT, GE, AND, OR, NOT, // == != < <= > >= && || !
    ASSIGN, // =
    LPAREN, RPAREN, // ( )
    EOL, STOP // end of line, tell parser to stop
  }

  string value;
  LexemeType type;
  this(string value, LexemeType type) {
    this.value = value;
    this.type = type;
  }
  override string toString() {
    switch(type) {
      case Ltype.EOL:
        return "EOL";
      case Ltype.STOP:
        return "STOP";
      default:
        return value;
    }
  }
  override string name() {
    return value;
  }
}
alias Ltype = Lexeme.LexemeType;

class Expression : Node {
  enum ExpressionType {
    BIN, UN
  }
  Node[] contents;
  ExpressionType type;
  this(Node[] contents, ExpressionType type) {
    this.contents = contents;
    this.type = type;
  }
  override string toString() {
    return format("EXPR_%s(%s)", type, nodeArrayToString(contents));
  }
  override string name() {
    return "EXPRESSION";
  }
}
alias Etype = Expression.ExpressionType;

class Statement : Node {
  enum StatementType {
    PRINT, PRINTLN, GOTO, CALL, RETURN, ASSIGN, NOP
  }
  Node[] contents;
  StatementType type;
  this(Node[] contents, StatementType type) {
    this.contents = contents;
    this.type = type;
  }
  override string toString() {
    return format("STMT_%s(%s)", type, nodeArrayToString(contents));
  }
  override string name() {
    return "STATEMENT";
  }
}
alias Stype = Statement.StatementType;