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
#   traverse(tree) do |one, two, ...|
#     # body omitted
#   end
#
def traverse(tree, &func)
  func.call(tree)
  tree.children.each { |child| traverse(child, &func) } unless tree.empty?
end

# MAIN
ARGV.each do |arg|
  parser = Peephole::Parser.new(open(arg))
  traverse(parser.start.tree) { |node| puts node.text }
end

