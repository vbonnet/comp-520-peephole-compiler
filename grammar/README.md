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


## Output ##
------------

Ohh boy!


## Grammar Style Guide ##
---------------------------

These things, they take time.

## Some Thoughts ##
-------------------
* You can't nest instruction sets, and honesly you shouldn't able to... so there
* We don't enforce that names are unique yet, please just make the unique within the context
(the rule, or declarations).  The progam will likely run, it just won't generate what you want
