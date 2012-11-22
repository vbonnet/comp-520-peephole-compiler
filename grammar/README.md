# The Language #
----------------

This language is built to be a somewhat visiual language; it is meant to resemble an actual Jasmin
bytecode sequence. Note that the language is not newline agnostic.  Unfortunately our current
implemenation relies on the instructions being alone on each line, and not seperated by more than
one newline.  That's possibly a weakness of the language, but for now it's a design decision that's
served us well.

**Note** that the `ldc` Jamsin instructions have been split into `ldc_int` and `ldc_string`.  This is
to 1) tell the compiler what you're loading 2) reflect the same split in `optimize.c`.  The `iconst`
instruction also doesn't exist, it is subsumed into the `ldc_int` isntruction.  All other jasmin
are declared nomally.

A few examples of this language can be found at
[`tests/sample.pattern`](https://github.com/vbonnet/Peephole-Compiler/blob/master/tests/sample.pattern).
This contains the patterns given by the ` patterns.h` file but translated into this language.

There are two top level elements in the lanugage: `DECLARATION`s, and `RULE`s

### `DECLARATION`s: ###
=======================

The language allows you to declare new instruction types that represent a set of Jasmin instructions
and use those isntructions in the first half of the rule.  A c method will be generated for each
instruction in the set.

#### Format: ####

    _name_ = { _jasmin_instr_1_ | _jasmin_instr_2_ | ... }

#### Example: ####

    add_sub = { iadd | isub }

### `RULE`s: ###
================

These are the part that will actually get compiled to c code.  They are comprised essentially of
two large parts.  The first is the instructions, this is essentially the 'pattern match' to be
found in the Jasmin instructions.  The second half is what the code should output if the first
half is matched.

The first half (to be matched) is a list of `INSTRUCTION`s separated by newlines.  The second half
is a list of `STATEMENTS` also separated by newlines.  There is also a token '-->' use to separate
the two halves, and a name for the rule.  The name will be used in code generation to identify the
rule.

Format:

    RULE: _name_
    ...
    _instr_ (: _name_)?
    ...
    -->
    ...
    _statement_
    ...


### `INSTRUCTION`s: ###
=======================

Instructions are the pattern matching half of the rules.  Each line represents a single instruction
that should be seen in order for the rule to be actived.  Every instruction line can be named, this
is done by adding ': _name_' after the line.  This allows entire lines to be used in the statements
half of the rule without knowing at compile-time what the contents of the rule are.

**NOTE** Only variable sets should be named.  The grammar allows for any instruction to be named,
but this could break things in subtle (or not so subtle) ways.  The actual instruction for a named
line should be: an instruction type declared in the grammar, an inline instruction set, or an
instruction count.  If you want to reuse a fixed instruction with the same argument as it currently
has (ex: `istore x`) just rewrite that rule exactly in the statements.  That'll create a new
instruction with the same argument.

There are a few types of intructions:

`_jasmin_instr_  _argument_?`
  * Pure and simply jasmin instruction with a possible argument

`_declared_type_  _argument_?`
  * A set of possible instructions, each instruction must have the same number of arguments (if any)

`{_jasmin_instr | .. }  _argument_?`
  * An inlined instruction set.  Each instruction must have the same number of arguments (if any)

`[_#_]`
  * An instruction count, this can represent any instruction, though there must be exactly # of them.

`[*]`
  * Any number of instructions, should not be used at the end of a rule


### `STATEMENT`s: ###
=====================

The statements are what will be created should the first half of the rule even match.  These are
essentially a list of Jasmin instructions to create, except for the switch statement which is
a set of possible jasmin instructions.  The actual set that will be created depends on the
runtime type of the variable being switched upon.  This is done in the c code by simply creating
a different method for each possible case.


There are a few types of statements:

`_jasmin_instruction_  _expression_?`
  * This creates the corresponding Jasmin bytecode.  If an argument is present it should have been
declared in the first half of this rule.  This will take the argument value (in the original
bytecode) and use it for the newly created instruction.

`_named_instruction_`
  * A simple variable name, this variable must represent one of the named instructions.  It copies
the entire intruction as it was in the original bytecode

`switch (_named_instruction_) { ... }`
  * This takes a named instruction from the first half of the code and switches on the type of that
instruction.  Each case will create a new c method in the output, the code generated for each type
is based on the instruction list within the corresponding case.

`if (_condition_) { ... } `
 * This statement conditions on the runtime value of an argument.  It can be used to check whether
two arguments have the same value (x == x) or if one argument has a particular value (x == 1).
More complex expressions can be written if need be.  **Note** this feature might not be in as clean
as state as it should be.  Each branch in an if statement is assumed to return.  This shouldn't be
correct but was the easiest way to code it for now.  Subject to change.


### `EXPRESSION`s ###
=====================

These allow you to take the runtime value of two arguments and add, subtract, divide, multiply, and
modulo them.  This is used in statements in order to reuse or transform the values or arguments
matched by the rule.

Example:

    (x + y + z) % z


### `CONTIDION`s ###
====================

These allow you to condition on the runtime value of two arguments.  This is used in if statements
to determine what instructions to used in replacement.

Example:

    (x != y)
    (x == 1 || y == 1)


## Output ##
------------

Ohh boy!

**the indentation is wrong.  /me cries**


## Grammar Style Guide ##
---------------------------

These things, they take time.

## Some Thoughts ##
-------------------
* You can't nest instruction sets, and honesly you shouldn't able to... so there
* We don't enforce that names are unique yet, please just make the unique within the context
(the rule, or declarations).  The progam will likely run, it just won't generate what you want
