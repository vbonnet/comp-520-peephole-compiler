# Generation #

## Case by Case generation ##
=============================

**TODO**

## Example Output ##
====================

Example: the `positive_increment` rule in the sample.pattern file.

    RULE: positive_increment
    iload x
    ldc_int k
    iadd
    istore y
    -->
    if (x == y && 0 <= k && k <= 127) {
      iinc x y
    }

Should generate c code that looks like this:

~~~~~ c
int positive_increment(CODE **c) {

  /* iload x */
  CODE *instr_1 = *c;
  int arg_x;
  if (!is_iload(instr_1, &arg_x)) {
    return 0;
  }

  /* ldc_int k */
  CODE *instr_2 = next(instr_1);
  int arg_k;
  if (!is_ldc_int(instr_2, &arg_k)) {
    return 0;
  }

  /* iadd */
  CODE *instr_3 = next(instr_2);
  if (!is_iadd(instr_3)) {
    return 0;
  }

  /* iload y */
  CODE *instr_4 = next(instr_3);
  int arg_y;
  if (!is_istore(instr_4, &arg_y)) {
    return 0;
  }

  /* --> */

  /* if (x == y && 0 <= k && k <= 127)  */
  if ((arg_x == arg_y) && (0 <= arg_k) && (arg_k <= 127)) {
    /* iinc x y */
    CODE *statement_1 = makeCODEiinc(arg_x, arg_y, NULL);
    return replace(c, 4, statement_1);
  }
  return 0;
}
~~~~~


## Current State ##
===================

Unfortunately We are haven't quite implemented everything we would like to.  This is what the rule
above will actually generate in the latest code (as of writing this file).

~~~~~ c
int positive_increment(CODE **c) {

  CODE *instr_1 = *c;
  int arg_x;
  if (!is_iload(instr_1, &arg_x)) {
    return 0;
  }

  CODE *instr_2 = next(instr_1);
  int arg_k;
  if (!is_ldc_int(instr_2, &arg_k)) {
    return 0;
  }

  CODE *instr_3 = next(instr_2);
  if (!is_iadd(instr_3)) {
    return 0;
  }

  CODE *instr_4 = next(instr_3);
  int arg_y;
  if (!is_istore(instr_4, &arg_y)) {
    return 0;
  }

  if (((arg_x == arg_y) && (0 <= arg_k) && (arg_k <= 127))) {
    CODE *statement_1 = makeCODEiinc(arg_x, arg_y, NULL);
    return replace(c, 4, statement_1);
  }
  return 0;
}
~~~~~
