grammar Peephole;

options {
  language = Ruby;
}

JASMIN_INSTR
  : 'return' | 'areturn' | 'ireturn'
  | 'iadd' | 'isub' | 'imul' | 'idiv' | 'irem'
  | 'ldc' | 'iconst'
  ;

ID : ('_'|'a'..'z'|'A'..'Z')+;

INT : '0'..'9'+;
NEWLINE : '\r'? '\n' ;


/*********************************
 *              SKIP             *
 *********************************/

WHITESPACE        :  (' '|'\t')+                    { skip(); };
MULTILINE_COMMENT :  '/*' (.)* '*/' { skip(); };


/*********************************
 *             START             *
 *********************************/

patterns : rule+ | declaration*;

/************ RULES **************/

rule
  : 'RULE:' name NEWLINE declaration+ '-->' statement*
  ;

name : ID ;


decleration
  : ID ID? (':' ID)? NEWLINE
  | '[' INT ']'   (':' ID)?
  | '[' '...' ']' (':' ID)?
  ;

statement
  : switch_statement NEWLINE
  | JASMIN_INSTR expression? NEWLINE
  ;

switch_statement : 'switch' '(' ID ')' '{' NEWLINE case_statement+ NEWLINE'}';
case_statement : JASMIN_INSTR ':' statement* ';' NEWLINE;


/********** EXPRESSIONS **********/

add : '+' | '-';
expression : mult_expression (add mult_expression)*;

mult : '*' | '/';
mult_expression : rem_expression (mult rem_expression)*;

remainder : '%';
rem_expression : atomic_expression (remainder atomic_expression)*;

atomic_expression
  : INT
  | ID
  | '(' expression ')'
  ;


/********* DECLARATIONS **********/

declaration
  : ID '=' '{' JASMIN_INSTR ('|' JASMIN_INSTR)* '}'
  ;
