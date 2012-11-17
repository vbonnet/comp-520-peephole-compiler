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

  /* INSTRUCTIONS */
  NAMED_INSTRUCTION;
  INSTRUCTION;
  INSTRUCTION_SET;
  INSTRUCTION_COUNT;

  /* INSTRUCTIONS */
  STATEMENT_CASE;
  STATEMENT_SWITCH;
  STATEMENT_VARIABLE;
  STATEMENT_INSTRUCTION;

  /* EXPRESSIONS */
  EXPRESSION_ADD;
  EXPRESSION_DIVIDE;
  EXPRESSION_SUBTRACT;
  EXPRESSION_MULTIPLY;
  EXPRESSION_REMAINDER;
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
  : (rule | declaration | T_NEWLINE)* EOF
      -> ^(START declaration* rule*)
  ;

/* RULES */

rule
  : T_RULE T_COLON rule_name T_NEWLINE (named_instruction T_NEWLINE)+ T_R_ARROW T_NEWLINE (statement T_NEWLINE)*
      ->  ^(RULE rule_name named_instruction+ statement*)
  ;

rule_name
  : name=T_VARIABLE
      -> $name
  ;

/* DECLARATIONS */

declaration
  : var=T_VARIABLE T_EQUAL instruction_set T_NEWLINE
      ->  ^(DECLARATION $var instruction_set)
  ;

/* INSTRUCTIONS */

named_instruction
  : instruction T_COLON name=T_VARIABLE
      -> ^(NAMED_INSTRUCTION $name instruction)
  | instruction
  ;

instruction
  : (instr=T_JASMIN_INSTRUCTION | instr=T_VARIABLE) arg=T_VARIABLE?
      -> ^(INSTRUCTION $instr $arg?)
  | T_L_BRACKET val=T_INT T_R_BRACKET
      -> ^(INSTRUCTION_COUNT $val)
  | T_L_BRACKET val=T_STAR T_R_BRACKET
      -> ^(INSTRUCTION_COUNT $val)
  | instruction_set
  ;

instruction_set
  : T_L_BRACE instr+=T_JASMIN_INSTRUCTION (T_BAR instr+=T_JASMIN_INSTRUCTION)* T_R_BRACE
      -> ^(INSTRUCTION_SET $instr+)
  ;

/* STATEMENTS */

statement
  : switch_statement
  | statement_no_switch
  ;

statement_no_switch
  : instr=T_JASMIN_INSTRUCTION add_expression?
      -> ^(STATEMENT_INSTRUCTION $instr add_expression?)
  | var=T_VARIABLE
      -> ^(STATEMENT_VARIABLE $var)
  ;

switch_statement
  : T_SWITCH T_L_PAREN val=T_VARIABLE T_R_PAREN T_NEWLINE? T_L_BRACE T_NEWLINE case_statement+ T_R_BRACE
      -> ^(STATEMENT_SWITCH $val case_statement+)
  ;

case_statement
  : val=T_JASMIN_INSTRUCTION T_COLON T_NEWLINE (stmts+=statement_no_switch T_NEWLINE)* T_SEMI_COLON T_NEWLINE
      -> ^(STATEMENT_CASE $val $stmts*)
  ;

/* EXPRESSIONS */

add_expression
  : sub_expression (T_PLUS sub_expression)*
  ;

sub_expression
  : mul_expression (T_MINUS mul_expression)*
  ;

mul_expression
  : div_expression (T_STAR div_expression)*
  ;

div_expression
  : rem_expression (T_SLASH rem_expression)*
  ;

rem_expression
  : atomic_expression (T_MOD atomic_expression)*
  ;

atomic_expression
  : val=T_INT
      -> $val
  | var=T_VARIABLE
      -> $var
  | T_L_PAREN add_expression T_R_PAREN
      -> add_expression
  ;
