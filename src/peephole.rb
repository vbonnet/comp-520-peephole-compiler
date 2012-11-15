#!/usr/bin/env ruby

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative( path )
      require File.join(File.dirname(__FILE__), path)
    end
  end
end

require_relative 'grammar/PeepholeParser.rb'

ARGV.each do |a|
  f = open(a)
  parser = Peephole::Parser.new( f )
end
