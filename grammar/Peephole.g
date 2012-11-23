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

  T_IF   = 'if';
  T_ELSE = 'else';

  T_AND = '&&';
  T_OR  = '||';
  T_EQ  = '==';
  T_NE  = '!=';
  T_LE  = '<=';
  T_GE  = '>=';
  T_LT  = '<';
  T_GT  = '>';

  /* AST NODES */

  /* TOP LEVEL NODES */
  START;
  PATTERN;
  DECLARATION;
  RULE;

  /* INSTRUCTIONS */
  NAMED_INSTRUCTION;
  UNNAMED_INSTRUCTION;
  INSTRUCTION;
  INSTRUCTION_SET;
  INSTRUCTION_COUNT;

  /* STATEMENTS */
  STATEMENT_IF;
  STATEMENT_CASE;
  STATEMENT_ELSE;
  STATEMENT_SWITCH;
  STATEMENT_VARIABLE;
  STATEMENT_COMPOUND;
  STATEMENT_INSTRUCTION;

  /* CONDITIONS */
  CONDITION_LE;
  CONDITION_LT;
  CONDITION_GE;
  CONDITION_GT;
  CONDITION_OR;
  CONDITION_AND;
  CONDITION_EQUAL;
  CONDITION_NEQUAL;

  /* EXPRESSIONS */
  EXPRESSION_ADD;
  EXPRESSION_DIVIDE;
  EXPRESSION_SUBTRACT;
  EXPRESSION_MULTIPLY;
  EXPRESSION_REMAINDER;
}

/* Jasmin Intruction "token".  Unfortunately cannot be an actual token, so is a production instead */

T_JASMIN_INSTRUCTION
  : 'new'
  | 'nop'           | 'i2c'
  | 'goto'
  | 'instanceof'    | 'checkcast'
  | 'iadd'          | 'isub'
  | 'imul'          | 'idiv'
  | 'irem'          | 'iinc'
  | 'ineg'
  | 'ifeq'          | 'ifne'
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
  | 'ldc_int'       | 'ldc_string'
  | 'aconst_null'
  | 'getfield'      | 'putfield'
  | 'invokevirtual' | 'invokenonvirtual'
  ;

T_INT : '0'..'9'+;
T_NEWLINE : '\r'? '\n' ;
T_VARIABLE : ('_'|'a'..'z'|'A'..'Z')+;

/* IGNORED TOKENS */

WHITESPACE        :  (' '|'\t')+                               { skip(); };
MULTILINE_COMMENT :  '/*' (options {greedy=false;} : .)* '*/'  { skip(); };

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
  : instruction  arg=T_VARIABLE* T_COLON name=T_VARIABLE
      -> ^(NAMED_INSTRUCTION $name instruction $arg*)
  | instruction  arg=T_VARIABLE*
      -> ^(UNNAMED_INSTRUCTION instruction $arg*)
  ;

instruction
  : (instr=T_JASMIN_INSTRUCTION | instr=T_VARIABLE)
      -> ^(INSTRUCTION $instr)
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
  : instr=T_JASMIN_INSTRUCTION add_expression*
      -> ^(STATEMENT_INSTRUCTION $instr add_expression*)
  | var=T_VARIABLE
      -> ^(STATEMENT_VARIABLE $var)
  | compound_if_statement
  ;

switch_statement
  : T_SWITCH T_L_PAREN val=T_VARIABLE T_R_PAREN T_NEWLINE? T_L_BRACE T_NEWLINE
    (case_statement T_NEWLINE)+ T_R_BRACE
      -> ^(STATEMENT_SWITCH $val case_statement+)
  ;

case_statement
  : val=T_JASMIN_INSTRUCTION T_COLON T_NEWLINE (stmts+=statement_no_switch T_NEWLINE)* T_SEMI_COLON
      -> ^(STATEMENT_CASE $val $stmts*)
  ;

compound_if_statement
  : stmts+=if_statement (T_ELSE stmts+=if_statement)* stmts+=else_statement?
      -> ^(STATEMENT_COMPOUND $stmts+)
  ;

if_statement
  : T_IF T_L_PAREN cond=condition T_R_PAREN T_L_BRACE T_NEWLINE (stmts+=statement T_NEWLINE)* T_R_BRACE
      -> ^(STATEMENT_IF $cond $stmts*)
  ;

else_statement
  : T_ELSE T_L_BRACE T_NEWLINE (stmts+=statement T_NEWLINE)*  T_R_BRACE
     -> ^(STATEMENT_ELSE $stmts*)
  ;

/* CONDITIONS */

condition
  /* or_condition (T_AND or_condition)*  */
  : (exp+=or_condition -> $exp) ((T_AND exp+=or_condition)+ -> ^(CONDITION_AND $exp+))?
  ;

or_condition
  /* atomic_condition (T_OR atomic_condition)*  */
  : (exp+=atomic_condition -> $exp) ((T_OR exp+=atomic_condition)+ -> ^(CONDITION_OR $exp+))?
  ;

atomic_condition
  : (left=T_VARIABLE | left=T_INT) op=condition_operator (right=T_VARIABLE | right=T_INT)
      -> ^($op $left $right)
  | T_L_PAREN cond=condition T_R_PAREN
      -> $cond
  ;

condition_operator
  : T_NE -> ^(CONDITION_NEQUAL)
  | T_EQ -> ^(CONDITION_EQUAL)
  | T_LT -> ^(CONDITION_LT)
  | T_LE -> ^(CONDITION_LE)
  | T_GT -> ^(CONDITION_GT)
  | T_GE -> ^(CONDITION_GE)
  ;


/* EXPRESSIONS */

/* NOTE 1 - These productions require two rules.  One for the first_exp -> second_exp rule and the other for the
 *         fist_exp -> second_exp (TOKEN second_exp)+ rule.  Unfortunately the only way to do this is to nest the
 *         AST transformation rules into the actual production.  This makes things rather ugly to read, so the actual
 *         production rule is witten in comments next to the AST tranformed one.
 *
 * NOTE 2 - It gets even worse, because the rule |_| -> (a -> ^A) (a* -> ^B) will actually always create a B node in
 *         the AST.  This makes some level of sense, as we match the '*' part of the production zero times and can
 *         return the whole production.  It does however make AST transformation rather tricky.  The trick used here
 *         is to instead use the (equivalent) rule |_| -> (a -> ^A) (a+ -> ^B)?.  Turns out adding the '?' token to
 *         rule will allow the first match to return an A and the second to return a B.  All fixed!
 *
 * WHY do all this?  Good question.  A simple {a_exp -> b_exp (^T_PLUS b_exp)* rule (note the '^'  character next
 *   to T_PLUS) would have created a hierarchy with T_PLUS AST nodes that have a "left" and "right" |b_exp| node.
 *   This would work fine, but it's BORING.  Creating the AST nodes in this way allows us to create one single AST
 *   node (ex. ADD_EXP) which contains two or more (<- imporant bit) children.  Yay, we've managed to flaten the tree
 *   a bit!  This makes for a cool optimization, particularly useful had we been writing a grammar for a bigger
 *   programming language.  Maybe not exactly worth it for this particular case but IT'S COOL (TM), so bite me.
 */

add_expression
  /*  => sub_expression (T_PLUS sub_expression)*  */
  : (exp+=sub_expression -> sub_expression) ((T_PLUS exp+=sub_expression)+ -> ^(EXPRESSION_ADD $exp+))?
  ;

sub_expression
  /*  => mul_expression (T_MINUS mul_expression)*  */
  : (exp+=mul_expression -> mul_expression) ((T_MINUS exp+=mul_expression)+ -> ^(EXPRESSION_SUBTRACT $exp+))?
  ;

mul_expression
  /*  => div_expression (T_STAR div_expression)*  */
  : (exp+=div_expression -> div_expression) ((T_STAR exp+=div_expression)+ -> ^(EXPRESSION_MULTIPLY $exp+))?
  ;

div_expression
  /*  => rem_expression (T_SLASH rem_expression)*  */
  : (exp+=rem_expression -> rem_expression) ((T_SLASH exp+=rem_expression)+ -> ^(EXPRESSION_DIVIDE $exp+))?
  ;

rem_expression
  /*  => atomic_expression (T_MOD atomic_expression)*  */
  : (exp+=atomic_expression -> atomic_expression) ((T_MOD exp+=atomic_expression)+ -> ^(EXPRESSION_REMAINDER $exp+))?
  ;

atomic_expression
  : val=T_INT
      -> $val
  | var=T_VARIABLE
      -> $var
  | T_L_PAREN add_expression T_R_PAREN
      -> add_expression
  ;
