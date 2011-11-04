module DBGet
  module Utils
    def randomize(size)
      chars = ('a'..'z').to_a + ('A'..'Z').to_a
      (0...size).collect { chars[Kernel.rand(chars.length)] }.join
    end
  end
end
