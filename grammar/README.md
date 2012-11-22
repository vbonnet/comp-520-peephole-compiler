# The Language #
----------------

This language is built to be a somewhat visiual language; it is meant to resemble an actual Jasmin
bytecode sequence. Note that the language is not newline agnostic.  Unfortunately our current
implemenation relies on the instructions being alone on each line, and not seperated by more than
one newline.  That's possibly a weakness of the language, but for now it's a design decision that's
served us well.

There are two top level elements in the lanugage: `DECLARATION`s, and `RULE`s

`DECLARATION`s:

The language allows you to declare new instruction types that represent a set of Jasmin instructions
and use those isntructions in the first half of the rule.  A c method will be generated for each
instruction in the set.

Format:

    _name_ = { _jasmin_instr_1_ | _jasmin_instr_2_ | ... }

Example:

    add_sub = { iadd | isub }

`RULE`s:

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


`INSTRUCTION`s:



`STATEMENT`s:



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
