module selt.lexer;

import selt.node;

Lexeme[] lex(string code) {
  Lexeme[] result;
  string value;
  enum State {
    START, COMMENT
  }
  State state;
  void add() {
    if(value != "") {
      result ~= new Lexeme(value, Ltype.TERM);
      value = "";
    }
  }
  void op(string o, Ltype t) {
    add();
    result ~= new Lexeme(o, t);
  }
  for(int i = 0; i < code.length; i++) {
    char c = code[i];
    char next = i+1 < code.length ? code[i+1] : '\0';
    final switch(state) {
      case State.START:
        switch(c) {
          case ' ':
          case '\t':
            add();
            break;
          case '+':
            op("+", Ltype.ADD);
            break;
          case '-':
            op("-", Ltype.SUB);
            break;
          case '*':
            op("*", Ltype.MUL);
            break;
          case '/':
            op("/", Ltype.DIV);
            break;
          case '%':
            op("%", Ltype.MOD);
            break;
          case '~':
            op("~", Ltype.CON);
            break;
          case '@':
            op("@", Ltype.AT);
            break;
          case '&':
            if(next == '&') {
              op("&&", Ltype.AND);
              i++;
            } else {
              op("&", Ltype.LINE);
            }
            break;
          case '|':
            if(next == '|') {
              op("||", Ltype.OR);
              i++;
            } else {
              op("|", Ltype.DELINE);
            }
            break;
          case '=':
            if(next == '=') {
              op("==", Ltype.EQ);
              i++;
            } else {
              op("=", Ltype.ASSIGN);
            }
            break;
          case '!':
            if(next == '=') {
              op("!=", Ltype.NE);
              i++;
            } else {
              op("!", Ltype.NOT);
            }
            break;
          case '<':
            if(next == '=') {
              op("<=", Ltype.LE);
              i++;
            } else {
              op("<", Ltype.LT);
            }
            break;
          case '>':
            if(next == '=') {
              op(">=", Ltype.GE);
              i++;
            } else {
              op(">", Ltype.GT);
            }
            break;
          case '.':
            op(".", Ltype.INDEX);
            break;
          case '?':
            op("?", Ltype.LENGTH);
            break;
          case '(':
            op("(", Ltype.LPAREN);
            break;
          case ')':
            op(")", Ltype.RPAREN);
            break;
          case '#':
            state = State.COMMENT;
            break;
          case '`':
            op("", Ltype.TERM); // backtick represents the empty string
            break;
          case '\\':
            value ~= next;
            i++;
            break;
          default:
            value ~= c;
            break;
        }
        break;
      case State.COMMENT:
        break; // only individual lines are lexed so we don't need to find the end of the comment
    }
  }
  op("", Ltype.EOL);
  op("", Ltype.STOP);
  return result;
}