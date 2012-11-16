grammar Peephole;

options {
  language = Ruby;
  output = AST;
}

JASMIN_INSTR
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

start : patterns+ EOF;

patterns
  : rule
  | assign
  | NEWLINE
  ;

/************ RULES **************/

rule
  : 'RULE:' name NEWLINE (named_declaration NEWLINE)+ '-->' NEWLINE (statement NEWLINE)*
  ;

name : ID ;

named_declaration : declaration (':' ID)? ;

declaration
  : (JASMIN_INSTR | ID) ID?
  | '[' INT ']'
  | '[' '...' ']'
  | instruction_set
  ;

statement
  : ID
  | switch_statement
  | statement_no_switch
  ;

statement_no_switch
  : JASMIN_INSTR expression?
  ;

switch_statement : 'switch' '(' ID ')' '{' NEWLINE case_statement+ '}';
case_statement : JASMIN_INSTR ':' NEWLINE (statement_no_switch NEWLINE)* ';' NEWLINE;


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

assign : ID '=' instruction_set NEWLINE;
instruction_set : '{' JASMIN_INSTR ('|' JASMIN_INSTR)* '}';
