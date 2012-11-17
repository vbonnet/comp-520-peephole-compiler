grammar Peephole;

options {
  language = Ruby;
  output   = AST;
}

tokens {
  EQUAL = '=';
  PLUS  = '+';
  MINUS = '-';
  STAR  = '*';
  SLASH = '/';
  MOD   = '%';

  L_PAREN   = '(';
  R_PAREN   = ')';
  L_BRACE   = '{';
  R_BRACE   = '}';
  L_BRACKET = '[';
  R_BRACKET = ']';

  BAR        = '|';
  COLON      = ':';
  SEMI_COLON = ';';

  R_ARROW = '-->';

  SWITCH = 'switch';
  RULE   = 'RULE';

  START;
  PATTERN;
  DECLARATION;
  RULE;
}

JASMIN_INSTRUCTION
  : 'new'
  | 'nop'           | 'i2c'
  | 'goto'
  | 'instanceof'    | 'checkcast'
  | 'iadd'          | 'isub'
  | 'imul'          | 'idiv'
  | 'irem'          | 'iinc'
  | 'ineg'
  | 'ifeq'          | 'ifneq'
  | 'ifnull'        | 'ifnonnull'
  | 'if_acmpeq'     | 'if_acmpne'
  | 'if_icmpeq'     | 'if_icmpne'
  | 'if_icmpgt'     | 'if_icmplt'
  | 'if_icmple'     | 'if_icmpge'
  | 'return'
  | 'areturn'       | 'ireturn'
  | 'astore'        | 'istore'
  | 'aload'         | 'iload'
  | 'dup'           | 'pop'
  | 'swap'
  | 'ldc'           | 'iconst'
  | 'aconst_null'
  | 'getfield'      | 'putfield'
  | 'invokevirtual' | 'invokenonvirtual'
  ;

VARIABLE : ('_'|'a'..'z'|'A'..'Z')+;

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

start : (rule | declaration | NEWLINE)* EOF -> ^(START declaration* rule*);

/************ RULES **************/

rule
  : RULE COLON name NEWLINE (named_instruction NEWLINE)+ R_ARROW NEWLINE (statement NEWLINE)*
      ->  ^(RULE)
  ;

name : VARIABLE ;

named_instruction
  : instruction (COLON VARIABLE)? ;

instruction
  : (JASMIN_INSTRUCTION | VARIABLE) VARIABLE?
  | L_BRACKET INT R_BRACKET
  | L_BRACKET STAR R_BRACKET
  | instruction_set
  ;

statement
  : VARIABLE
  | switch_statement
  | statement_no_switch
  ;

statement_no_switch : JASMIN_INSTRUCTION expression? ;

switch_statement
  : SWITCH L_PAREN VARIABLE R_PAREN NEWLINE?
    L_BRACE NEWLINE case_statement+ R_BRACE;

case_statement
  : JASMIN_INSTRUCTION COLON NEWLINE
    (statement_no_switch NEWLINE)*
    SEMI_COLON NEWLINE;

/********** EXPRESSIONS **********/

expression : mult_expression ((PLUS | MINUS) mult_expression)*;
mult_expression : rem_expression ((STAR | SLASH) rem_expression)*;
rem_expression : atomic_expression (MOD atomic_expression)*;

atomic_expression
  : INT
  | VARIABLE
  | L_PAREN expression R_PAREN
  ;

/********* DECLARATIONS **********/

declaration
  : VARIABLE EQUAL instruction_set NEWLINE  ->  ^(DECLARATION)
  ;

instruction_set
  : L_BRACE JASMIN_INSTRUCTION (BAR JASMIN_INSTRUCTION)* R_BRACE
  ;
