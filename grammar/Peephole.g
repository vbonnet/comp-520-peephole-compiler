grammar Peephole;

options {
  language = Ruby;
  output   = AST;
}


tokens {
  /* TOKENS */

  T_EQUAL = '=';
  T_PLUS  = '+';
  T_MINUS = '-';
  T_STAR  = '*';
  T_SLASH = '/';
  T_MOD   = '%';

  T_L_PAREN   = '(';
  T_R_PAREN   = ')';
  T_L_BRACE   = '{';
  T_R_BRACE   = '}';
  T_L_BRACKET = '[';
  T_R_BRACKET = ']';

  T_BAR        = '|';
  T_COLON      = ':';
  T_SEMI_COLON = ';';

  T_R_ARROW = '-->';

  T_SWITCH = 'switch';
  T_RULE   = 'RULE';

  /* AST NODES */

  /* TOP LEVEL NODES */
  START;
  PATTERN;
  DECLARATION;
  RULE;
}

/* Jasmin Intruction "token".  Unforutnatnely cannot be an actual token, so is a production instead */

T_JASMIN_INSTRUCTION
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

T_INT : '0'..'9'+;
T_NEWLINE : '\r'? '\n' ;
T_VARIABLE : ('_'|'a'..'z'|'A'..'Z')+;


/* IGNORED TOKENS */

WHITESPACE        :  (' '|'\t')+     { skip(); };
MULTILINE_COMMENT :  '/*' (.)* '*/'  { skip(); };

/* START */

start
  : (rule | declaration | T_NEWLINE)* EOF -> ^(START declaration* rule*)
  ;

/* RULES */

rule
  : T_RULE T_COLON name T_NEWLINE (named_instruction T_NEWLINE)+ T_R_ARROW T_NEWLINE (statement T_NEWLINE)*
      ->  ^(RULE)
  ;

name
  : T_VARIABLE
  ;

/* DECLARATIONS */

declaration
  : T_VARIABLE T_EQUAL instruction_set T_NEWLINE  ->  ^(DECLARATION)
  ;

/* INSTRUCTIONS */

named_instruction
  : instruction (T_COLON T_VARIABLE)?
  ;

instruction
  : (T_JASMIN_INSTRUCTION | T_VARIABLE) T_VARIABLE?
  | T_L_BRACKET T_INT T_R_BRACKET
  | T_L_BRACKET T_STAR T_R_BRACKET
  | instruction_set
  ;

instruction_set
  : T_L_BRACE T_JASMIN_INSTRUCTION (T_BAR T_JASMIN_INSTRUCTION)* T_R_BRACE
  ;

/* STATEMENTS */

statement
  : T_VARIABLE
  | switch_statement
  | statement_no_switch
  ;

statement_no_switch
  : T_JASMIN_INSTRUCTION expression?
  ;

switch_statement
  : T_SWITCH T_L_PAREN T_VARIABLE T_R_PAREN T_NEWLINE? T_L_BRACE T_NEWLINE case_statement+ T_R_BRACE
  ;

case_statement
  : T_JASMIN_INSTRUCTION T_COLON T_NEWLINE (statement_no_switch T_NEWLINE)* T_SEMI_COLON T_NEWLINE
  ;

/* EXPRESSIONS */

expression
  : mult_expression ((T_PLUS | T_MINUS) mult_expression)*
  ;

mult_expression
  : rem_expression ((T_STAR | T_SLASH) rem_expression)*
  ;

rem_expression
  : atomic_expression (T_MOD atomic_expression)*
  ;

atomic_expression
  : T_INT
  | T_VARIABLE
  | T_L_PAREN expression T_R_PAREN
  ;
