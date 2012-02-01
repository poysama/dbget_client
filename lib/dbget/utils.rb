require 'benchmark'

module DBGet
  module Utils
    def self.say(message, subitem = false)
      puts "#{subitem ? "   ->" : "--"} #{message}"
    end

    def self.say_with_time(message)
      say(message)
      result = nil
      time = Benchmark.measure { result = yield }
      say "%.4fs" % time.real, :subitem
      say("#{result} rows", :subitem) if result.is_a?(Integer)
      result
    end

    def self.randomize(size)
      chars = ('a'..'z').to_a + ('A'..'Z').to_a
      (0...size).collect { chars[Kernel.rand(chars.length)] }.join
    end
  end
end
