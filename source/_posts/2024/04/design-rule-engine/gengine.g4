grammar gengine;

primary: ruleEntity+;
// 规则定义
ruleEntity:  RULE ruleName ruleDescription? salience? BEGIN ruleContent END;
ruleName : stringLiteral;
ruleDescription : stringLiteral;
salience : SALIENCE integer;
// 规则体
ruleContent : statements;
statements: statement* returnStmt?;

// 基本语句
statement : ifStmt | functionCall | assignment | forStmt | breakStmt;

expression : mathExpression
            | expression comparisonOperator expression
            | expression logicalOperator expression
            | notOperator ? expressionAtom
            | notOperator ? LR_BRACKET expression  RR_BRACKET
            ;

mathExpression : mathExpression  mathMdOperator mathExpression
               | mathExpression  mathPmOperator mathExpression
               | expressionAtom
               | LR_BRACKET mathExpression RR_BRACKET
               ;

expressionAtom
    : functionCall
    | constant
    | variable
    ;
assignment : variable assignOperator (mathExpression| expression);
returnStmt : RETURN expression?;
ifStmt : IF expression LR_BRACE statements RR_BRACE elseIfStmt*  elseStmt?;
elseIfStmt : ELSE IF expression LR_BRACE statements RR_BRACE;
elseStmt : ELSE LR_BRACE statements RR_BRACE;
forStmt : FOR assignment SEMICOLON expression SEMICOLON assignment LR_BRACE statements RR_BRACE;
breakStmt: BREAK;

constant
    : booleanLiteral
    | integer
    | stringLiteral
    ;
functionArgs
    : (constant | variable  | functionCall | expression)  (','(constant | variable | functionCall | expression))*
    ;
integer : MINUS? INT;
stringLiteral: DQUOTA_STRING;
booleanLiteral : TRUE | FALSE;
functionCall : SIMPLENAME LR_BRACKET functionArgs? RR_BRACKET;
variable :  SIMPLENAME | DOTTEDNAME;
mathPmOperator : PLUS | MINUS;
mathMdOperator : MUL | DIV;
comparisonOperator : GT | LT | GTE | LTE | EQUALS | NOTEQUALS;
logicalOperator : AND | OR;
assignOperator: SET;
notOperator: NOT;

// 关键字
NIL                         : 'nil';
RULE                        : 'rule';
AND                         : '&&';
OR                          : '||';

IF                          : 'if';
ELSE                        : 'else';
RETURN                      : 'return';
FOR                         : 'for';
BREAK                       : 'break';

TRUE                        : 'true';
FALSE                       : 'false';
SALIENCE                    : 'salience';
BEGIN                       : 'begin';
END                         : 'end';

SIMPLENAME :  ('a'..'z' |'A'..'Z'| '_')+ ( ('0'..'9') | ('a'..'z' |'A'..'Z') | '_' )*;

INT : '0'..'9' +;
PLUS                        : '+';
MINUS                       : '-';
DIV                         : '/';
MUL                         : '*';

EQUALS                      : '==';
GT                          : '>';
LT                          : '<';
GTE                         : '>=';
LTE                         : '<=';
NOTEQUALS                   : '!=';
NOT                         : '!';
SET                         : '=';

SEMICOLON                   : ';';
LR_BRACE                    : '{';
RR_BRACE                    : '}';
LR_BRACKET                  : '(';
RR_BRACKET                  : ')';
DOT                         : '.';
DQUOTA_STRING               : '"' ( '\\'. | '""' | ~('"'| '\\') )* '"';
DOTTEDNAME                  : SIMPLENAME DOT SIMPLENAME;

// 过滤token
SL_COMMENT: '//' .*? '\n' -> skip;
WS  :   [ \t\n\r]+ -> skip;