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
#
# Example
#
#   on_enter = lambda do |one, two, ...|
#     # body omitted
#   end
#   on_exit = lambda do |one, two, ...|
#     # body omitted
#   end
#   traverse(tree, on_enter, on_exit)
#
def traverse(tree, on_enter, on_exit = nil)
  on_enter.call(tree)
  tree.children.each { |child| traverse(child, on_enter, on_exit) } unless tree.empty?
  on_exit.call(tree) if on_exit != nil
end

# MAIN
ARGV.each do |arg|
  parser = Peephole::Parser.new(open(arg))

  indent = 0
  print = lambda do |node|
    s = ' ' * (2 * indent)
    indent += 1
    s << node.text.to_s
    puts s
  end
  traverse(parser.start.tree, print, lambda{ |_|  indent -= 1 })
end

