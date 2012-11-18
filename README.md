### Jasmin Peephole Visual Compiler ###

## Description ##
----------------

This compiler was created to generate code  for the peephole pattern portion of McGill's compilers course
([COMP 520](http://www.cs.mcgill.ca/~cs520/)). It takes as input a language defined specifically for this compiler
(explained more in [`grammar/README`](https://github.com/vbonnet/Peephole-Compiler/blob/master/README.md)).  The
language is designed to resemble the [Jasmin](http://jasmin.sourceforge.net/) bytecode while still allow for the
creation of complex patterns.  The output of the compiler is .c files that depend on the
[optimize.c](http://www.cs.mcgill.ca/~cs520/2012/joos/a-/optimize.c) API.

## Dependendices ##
-------------------

This project uses [ANTLR](http://antlr.org/) for its parser generator.  ANTLR provides many target languages, this
project is using the [Ruby target](http://antlr.ohboyohboyohboy.org/) for ANTLR.  The docs for the code generated
by this target can be found at http://rubydoc.info/github/ohboyohboyohboy/antlr3/.  Unfortuantely the docs themselves
are somewhat lacking as the main developer seems to have dropped the project.  Honestly given the support provided
for ANTLR+Ruby we probably should've picked a different language.  But @vbonnet wanted to code in Ruby, so that was
that.

## Installation ##
------------------

The first step in installation is to install the actual repo.

    git clone git://github.com/vbonnet/Peephole-Compiler.git

The repo comes with the ANTLR code inside the `lib/` directory.  However the Ruby target requires some ruby code not
included with the project.  To download this code simply run

    gem install antlr3

Now you're set to go!  To generate the Lexer+Parser simply run: (There will be a Makefile later, I'm just lazy)

     ./gen_grammar

That should generate `PeepholeLexer.rb` and `PeepholeParser.rb` inside `src/grammar/`.  From there you can run the
compiler by running:

    ruby src/peephole.rb

NOTE - This part is in the works, right now it only prints the AST

## Style guides ##
------------------

* The Ruby code should follow the [Github Ruby styleguide](https://github.com/styleguide/ruby)
* The grammar has its own style, defined in
[`grammar/README`](https://github.com/vbonnet/Peephole-Compiler/blob/master/README.md)

## Contributing ##
------------------

Go for it!  Submit a pull request, feel free.