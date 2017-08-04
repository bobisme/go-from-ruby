#!/usr/bin/env ruby

require 'ffi'

class NoNegativesError < StandardError; end

module GoSumLib
  extend FFI::Library
  ext = FFI::Platform::LIBSUFFIX
  ffi_lib "libsum.#{ext}"
  attach_function :Add, [:long_long, :long_long], :long_long
  attach_function :Sum, [:pointer, :long_long], :long_long
  attach_function :ToInt, [:string, :pointer], :long_long
  attach_function :FromInt, [:long, :pointer], :strptr

  def self.add(a, b)
    self.Add(a, b)
  end

  def self.sum(list)
    sum = 0
    FFI::MemoryPointer.new(:long_long, list.size) do |p|
      p.write_array_of_long_long(list)
      sum = self.Sum(p, list.size)
      # The memory of the pointer gets freed once this block exits.
    end
    sum
  end

  def self.to_int(input)
    out = nil
    FFI::MemoryPointer.new(:long_long, 1) do |out_pointer|
      err = self.ToInt(input, out_pointer)
      raise NoNegativesError, 'no negatives' if err == 1
      raise 'unspecified error' if err != 0
      result = out_pointer.read_array_of_long_long(1)
      out = result[0]
    end
    out
  end

  def self.from_int(input_string)
    out = nil
    FFI::MemoryPointer.new(:string, 1) do |out_pointer|
      err_msg, err_ptr = self.FromInt(input_string, out_pointer)
      raise err_msg unless err_ptr.null?
      res = out_pointer.read_array_of_pointer(1)
      out = res[0].read_string
    end
    out
  end
end

# = TESTING ===================================================================

puts "add #{GoSumLib.add(1, 2)} should be 3"
puts "sum #{GoSumLib.sum([1, 2])} should be 3"
puts "#{GoSumLib.to_int('100')} should be 100"

begin
  GoSumLib.to_int('-1')
rescue NoNegativesError => err
  puts "expected error: #{err}"
end

begin
  GoSumLib.to_int('abc')
rescue StandardError => err
  puts "expected error: #{err}"
end

puts "#{GoSumLib.from_int(100)} should be 100"

begin
  GoSumLib.from_int(-1)
rescue StandardError => err
  puts "expected error from go: #{err}"
end
