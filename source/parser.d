module selt.parser;

import selt.node;

Node[] parse(Lexeme[] lexemes) {
  Node[] stack;
  Lexeme next() {
    Lexeme l = lexemes[0];
    lexemes = lexemes[1..$];
    return l;
  }
  Lexeme peek() {
    return lexemes[0];
  }
  bool isLexeme(Node n, Ltype t) {
    return cast(Lexeme)n && (cast(Lexeme)n).type == t;
  }
  bool isTerm(Node n, string s) {
    return cast(Lexeme)n && (cast(Lexeme)n).type == Ltype.TERM && (cast(Lexeme)n).value == s;
  }
  bool exprOrTerm(Node n) {
    if(cast(Expression)n) return true;
    else return isLexeme(n, Ltype.TERM);
  }
  bool binop(Node n) {
    if(Lexeme l = cast(Lexeme)n)
      switch(l.type) {
        case Ltype.ADD:
        case Ltype.SUB:
        case Ltype.MUL:
        case Ltype.DIV:
        case Ltype.MOD:
        case Ltype.CON:
        case Ltype.EQ:
        case Ltype.NE:
        case Ltype.LT:
        case Ltype.LE:
        case Ltype.GT:
        case Ltype.GE:
        case Ltype.AND:
        case Ltype.OR:
        case Ltype.INDEX:
          return true;
        default:
          return false;
      }
    return false;
  }
  bool unop(Node n) {
    if(Lexeme l = cast(Lexeme)n)
      switch(l.type) {
        case Ltype.AT:
        case Ltype.LINE:
        case Ltype.DELINE:
        case Ltype.NOT:
        case Ltype.LENGTH:
          return true;
        default:
          return false;
      }
    return false;
  }
  int precedence(Node n) {
    if(Lexeme l = cast(Lexeme)n)
      switch(l.type) {
        case Ltype.CON:
          return 1;
        case Ltype.ADD:
        case Ltype.SUB:
          return 2;
        case Ltype.MUL:
        case Ltype.DIV:
        case Ltype.MOD:
          return 3;
        case Ltype.EQ:
        case Ltype.NE:
        case Ltype.LT:
        case Ltype.LE:
        case Ltype.GT:
        case Ltype.GE:
          return 4;
        case Ltype.AND:
          return 5;
        case Ltype.OR:
          return 6;
        case Ltype.AT:
        case Ltype.LINE:
        case Ltype.DELINE:
        case Ltype.NOT:
        case Ltype.INDEX:
        case Ltype.LENGTH:
          return 7;
        default:
          return 0;
      }
    return 0;
  }
  while(true) {
    Lexeme nxt = next();
    if(isLexeme(nxt, Ltype.STOP)) return stack;
    stack ~= nxt;
    bool reduced = true;
    while(reduced) {
      reduced = false;
      for(int i = 0; i < stack.length; i++) {
        Node[] seg = stack[i..$];
        void reduce(Node n) {
          stack = stack[0..i];
          stack ~= n;
          reduced = true;
        }
        // ==== Expression ====
        // e/t binop e/t
        if(seg.length == 3) {
          if(exprOrTerm(seg[0]) && binop(seg[1]) && exprOrTerm(seg[2]) && precedence(seg[1]) >= precedence(peek())) {
            reduce(new Expression([seg[0], seg[1], seg[2]], Etype.BIN));
            break;
          }
        }
        // unop e/t
        if(seg.length == 2) {
          if(unop(seg[0]) && exprOrTerm(seg[1]) && precedence(seg[0]) >= precedence(peek())) {
            reduce(new Expression([seg[0], seg[1]], Etype.UN));
            break;
          }
        }
        // ( e/t )
        if(seg.length == 3) {
          if(isLexeme(seg[0], Ltype.LPAREN) && exprOrTerm(seg[1]) && isLexeme(seg[2], Ltype.RPAREN)) {
            reduce(seg[1]);
            break;
          }
        }
        // ==== Statement ====
        if(seg.length == 3) {
          // print e/t EOL
          if(isTerm(seg[0], "print") && exprOrTerm(seg[1]) && isLexeme(seg[2], Ltype.EOL)) {
            reduce(new Statement([seg[1]], Stype.PRINT));
            break;
          }
          // println e/t EOL
          if(isTerm(seg[0], "println") && exprOrTerm(seg[1]) && isLexeme(seg[2], Ltype.EOL)) {
            reduce(new Statement([seg[1]], Stype.PRINTLN));
            break;
          }
          // goto e/t EOL
          if(isTerm(seg[0], "goto") && exprOrTerm(seg[1]) && isLexeme(seg[2], Ltype.EOL)) {
            reduce(new Statement([seg[1]], Stype.GOTO));
            break;
          }
          // call e/t EOL
          if(isTerm(seg[0], "call") && exprOrTerm(seg[1]) && isLexeme(seg[2], Ltype.EOL)) {
            reduce(new Statement([seg[1]], Stype.CALL));
            break;
          }
        }
        if(seg.length == 4) {
          // e/t = e/t EOL
          if(exprOrTerm(seg[0]) && isLexeme(seg[1], Ltype.ASSIGN) && exprOrTerm(seg[2]) && isLexeme(seg[3], Ltype.EOL)) {
            reduce(new Statement([seg[0], seg[2]], Stype.ASSIGN));
            break;
          }
        }
        if(seg.length == 1) {
          // EOL
          if(isLexeme(seg[0], Ltype.EOL)) {
            reduce(new Statement([], Stype.NOP));
            break;
          }
        }
        if(seg.length == 2) {
          // return EOL
          if(isTerm(seg[0], "return") && isLexeme(seg[1], Ltype.EOL)) {
            reduce(new Statement([], Stype.RETURN));
            break;
          }
        }
      }
    }
  }
}