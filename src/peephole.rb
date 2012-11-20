#!/usr/bin/env ruby

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(__FILE__), path)
    end
  end
end

require_relative 'grammar/PeepholeParser.rb'


# Internal: Prints all methods that can be called on this objects.  Each of method is ont its own line.
#
# obj - the object whose possible methods will be printed
#
# sideffect: prints method list to stdout
#
def list_methods(obj)
  puts obj.methods.sort.join("\n").to_s
end


# Public: Executes a depth fist traversal of a tree object and calls a function on each node as it is entered.
#
# tree - The ANTLR3::AST::BaseTree object to be traversed.
# func - The function to call on each node.
#
# Examples
#
#   apply(tree) do |one, two, ...|
#     # body omitted
#   end
#
def apply(tree, &func)
  traverse(tree, func)
end


# Public: Executes a depth first traversal on a tree object and carries calls two functions for each node. First
#         |on_enter| is called with the current node as argument as we enter the node (ie before the children are
#         traversed.  Then |traverse| iterates on all children (in doing so calling |on_enter| and |on_exit| on all
#         children nodes).  Finally |on_exit| is called on the node.
#
# tree     - The ANTLR3::AST::BaseTree object to be traversed.
# on_enter - The function to call on each node on the way down the tree.
# on_exit  - The function to call on each node on the way back up the tree.
# on_leaf  - The function to call on leaves as they are hit.
#
# Example
#
#   on_enter = lambda do |node|
#     # body omitted
#   end
#   on_exit = lambda do |node|
#     # body omitted
#   end
#   one_leaf = lamnda do |leaf|
#     # body omitted
#   end
#   traverse(tree, on_enter, on_exit)
#
def traverse(tree, on_enter, on_exit = nil, on_leaf = nil)
  on_enter.call(tree) unless on_enter == nil
  tree.children.each do |child|
    if child.empty?
      on_leaf.call(child) unless on_leaf == nil
    else
      traverse(child, on_enter, on_exit, on_leaf)
    end
  end
  on_exit.call(tree) unless on_exit == nil
end

# Public: Prints the AST to stdout
#
# tree - The ANTLR3::AST::BaseTree object to print.
#
# Example
#
#   This assumes the variable |tree| has been loaded with an AST generated form the string "int_oper={iadd|isub}"
#   print(tree)
#     # => "
#   START  :(22)
#   DECLARATION  :(24)
#     int_oper
#     INSTRUCTION_SET  :(28)
#        iadd
#        isub
#   "
#
def print_ast(tree)
  indent = 0
  print_node = lambda do |node|
    s = ' ' * (2 * indent)
    indent += 1
    s << node.text.to_s
    puts s << '  :(' << node.type.to_s << ')'
  end
  print_leaf = lambda do |leaf|
    s = ' ' * (2 * indent)
    puts s << leaf.text.to_s
  end
  traverse(tree, print_node, lambda{ |_|  indent -= 1 }, print_leaf)
end

#
#
def build_declaration_map(tree)
  include Peephole::TokenData

  declaration_map = {}

  tree.children.each do |declaration|
    if declaration.type == DECLARATION
      # find the name of the newly declared variable
      name = declaration.children[0].text

      # if two declarations have the same name throw an execptio to  be caught and show to the user
      throw 'redeclaration of instruction set' if declaration_map[name] != nil

      # find the set of instructions associated with this declaration
      set = declaration.children[1]
      instruction_set = Set.new
      set.each { |instr| instruction_set.add(instr.text) }

      # add {name => instruction_set} to the map
      declaration_map[name] = instruction_set
    else
      break
    end
  end

  return declaration_map
end

#
#
def declaration_string(name, next_instr)
  s =  'CODE *' << name + ' = '
  if (next_instr == '*c')
    s << next_instr << ";\n"
  else
    s << 'next(' << next_instr << ");\n"
  end
  next_instr.replace(name)
  return s
end

#
#
def build_declarations_format(rule, declarations)
  include Peephole::TokenData

  format = ''

  instr_index = 1;
  next_instr = '*c';
  # block to be run up entering a parent node
  in_a_node = lambda do |node|
    children = node.children

    case node.type
    when NAMED_INSTRUCTION
      # print the instruciton declaration
      name =  'instr_' << children[0].text
      format << '  ' << declaration_string(name, next_instr)
      instr_index += 1
    when UNNAMED_INSTRUCTION
      # number the isntruction and print the declaration
      name =  'instr_' << instr_index.to_s
      format << '  ' << declaration_string(name, next_instr)
      instr_index += 1
    when INSTRUCTION
      if declarations[children[0].text] == nil
        # print the actual instruction name if available
        instruction = children[0].text
      else
        # otherwise set is as variable to be hooked later
        instruction = "%s"
      end

      argument = nil
      if children[1] != nil
        # get the arguments name if it exists
        argument = 'arg_' << children[1].text
        # print the argument declaration
        format << '  int ' << argument << ";\n"
      end

      # print the instruction checking if statement
      format << '  if (!is_' << instruction << '(' << next_instr
      format << ", &" << argument unless argument == nil
      format << ")) {\n"
      format << '    ' << "return 0;\n"
      format << '  ' << "}\n"
    else
      next
    end
  end

  # code to be run when we exit a parent node
  out_a_node = lambda do |node|
    case node.type
    when NAMED_INSTRUCTION, UNNAMED_INSTRUCTION, INSTRUCTION
      format << "\n"
    else
      next
    end
  end

  traverse(rule, in_a_node, out_a_node)
  return format
end

#
#
def get_variable_instructions(rule, declarations)
  index = 1
  variable_instructions = []

  get_variable = lambda do |line|
    case line.type
    when INSTRUCTION
      instruction = line.children[0].text
      variable_instructions += [instruction] unless declarations[instruction] == nil
    when INSTRUCTION_SET
      # create a name for the new set we'll create
      name = 'inlined_' << index.to_s

      # create a set containing all the instructions in this declaration
      set = Set.new
      line.children.each { |instr| set.add(instr.text) }

      # add the set to |declarations|, add a new entry to |variable_instructions|, increment index
      declarations[name] = set
      variable_instructions += [name]
      index += 1
    end
  end

  traverse(rule, get_variable)
  return variable_instructions
end

#
#
def print_rule(rule, declarations)
  variable_instructions = get_variable_instructions(rule, declarations)

  signature_format = 'int ' << rule.children[0].text
  signature_format << ('_%s') * variable_instructions.size
  signature_format << "(CODE **c) {\n"

  # print the signature
  puts signature_format % variable_instructions

  # print the declarations
  declarations_format = build_declarations_format(rule, declarations)
  puts declarations_format % variable_instructions << "\n\n"

  # close off the method
  puts "}\n"

end

#
#
def print_c_code(tree)
  declarations = build_declaration_map(tree)

  include Peephole::TokenData
  tree.children.each do |rule|
    if rule.type == RULE
      print_rule(rule, declarations.clone)
    end
  end
end

# MAIN
ARGV.each do |arg|
  parser = Peephole::Parser.new(open(arg))
  print_c_code(parser.start.tree)
end

