
module Musel

  N_ARR = [0, 2, 4, 5, 7, 9, 11]
  HALVES_PER_SCALE = 12

  class NotePitch
    attr_accessor :note, :scale, :sharp_b
    attr_accessor :midi

    def initialize(name = nil)
      if name
        raise "unknown note #{name}" unless name.to_s =~ /^([a-z])([0-8])([#b]?)$/i
        c = ($1.unpack('c').first - 'a'.unpack('c').first - 2 + 7) % 7
        self.scale = $2.to_i
        if $3 == '#'
          self.sharp_b = 1
        elsif $3 == 'b'
          self.sharp_b = -1
        else
          self.sharp_b = 0
        end
        self.note = N_ARR[c]
        self.midi = HALVES_PER_SCALE * (self.scale + 1) + N_ARR[c] + self.sharp_b
      else
        self.note = 0
        self.scale = 3
        self.sharp_b = 0
        self.midi = 48
      end
    end

    def self.from_midi(midi_n)
      scale = midi_n / HALVES_PER_SCALE - 1
      note = midi_n % HALVES_PER_SCALE
      sharp_b = 0
      if N_ARR.index(note)
      else
        note -= 1
        sharp_b = 1
      end
      ret = NotePitch.new
      ret.note = note
      ret.scale = scale
      ret.sharp_b = sharp_b
      ret.midi = midi_n
      ret
    end

    def next_white(n = 1)
      if n < 0
        raise 'next white: parameter error'
      elsif n == 0
        self.dup
      elsif n == 1
        if N_ARR.include? self.note
          if self.note == 4 || self.note == 11
            delta = 1
          else
            delta = 2
          end
        else
          delta = 1
        end
        NotePitch.from_midi(self.midi + delta)
      else
        next_white(n - 1).next_white(1)
      end
    end

    def scale_up
      NotePitch.from_midi(self.midi + HALVES_PER_SCALE)
    end

    def to_s
      s = 'cdefgab'
      sb = [nil, '#', 'b']
      "#{s[self.note]}#{self.scale}#{sb[self.sharp_b]}"
    end
  end

end