
module Musel

  N_ARR = [0, 2, 4, 5, 7, 9, 11]
  HALF_NOTES_PER_SCALE = 12

  class NotePitch
    attr_reader :note, :scale, :sharp_b
    attr_reader :midi

    ##
    # def initialize(name = :g0)
    # def initialize(note, scale, sharp_b, midi)
    def initialize(*args)
      if args.size <= 0
        args = [:g0]
      end

      if args.size == 1
        if args.first.is_a? Numeric
          @midi = args.first
          @scale = @midi / HALF_NOTES_PER_SCALE - 1
          @note = @midi % HALF_NOTES_PER_SCALE
          @sharp_b = 0
          unless N_ARR.index(@note)
            @note -= 1
            @sharp_b = 1
          end
        else
          name = args.first
          raise "unknown note #{name}" unless name.to_s =~ /^([a-z])([0-8])([#b]?)$/i
          c = ($1.unpack('c').first - 'a'.unpack('c').first - 2 + 7) % 7
          @scale = $2.to_i
          if $3 == '#'
            @sharp_b = 1
          elsif $3 == 'b'
            @sharp_b = -1
          else
            @sharp_b = 0
          end
          @note = N_ARR[c]
          @midi = HALF_NOTES_PER_SCALE * (self.scale + 1) + N_ARR[c] + self.sharp_b
        end
      elsif args.size == 4
        @note, @scale, @sharp_b, @midi = args
      else
        raise 'note pitch initializer parameter error'
      end
    end

    def self.from_midi(midi_n)
      scale = midi_n / HALF_NOTES_PER_SCALE - 1
      note = midi_n % HALF_NOTES_PER_SCALE
      sharp_b = 0
      unless N_ARR.index(note)
        note -= 1
        sharp_b = 1
      end
      NotePitch.new(note, scale, sharp_b, midi_n)
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
      NotePitch.from_midi(self.midi + HALF_NOTES_PER_SCALE)
    end

    def to_s
      s = 'CDEFGAB'
      sb = [nil, '#', 'b']
      "#{s[N_ARR.index(self.note)]}#{self.scale}#{sb[self.sharp_b]}"
    end
  end

  class NoteDuration
    attr_reader :name
    ##
    # def initialize(name = :quarter)
    #   name = string or symbol
    #     'whole'
    #     'half'
    #     'quarter'
    #     'eighth'
    #     '8th'
    #     'sixteenth'
    #     '16th'
    #     'thirty second'
    #     'thirtysecond'
    #     '32nd'
    #     'sixty fourth'
    #     'sixtyfourth'
    #     '64th'
    # }
    # def initialize(millis)
    def initialize(name)
      @name = name.to_s
    end

  end

  class Note
    attr_reader :pitch, :duration, :strength
    def initialize(pitch, duration, strength = 127)
      @pitch = (pitch.is_a? NotePitch) ? pitch : NotePitch.new(pitch)
      @duration = (duration.is_a? NoteDuration) ? duration : NoteDuration.new(duration)
      @strength = strength
    end
    def to_s
      @pitch.to_s
    end
  end

  CHORD_COUNTS = {
      3 => 3,
      7 => 4
  }
  CHORD_TABLE = {
      3 => {
          major:  [0, 4, 7],
          minor:  [0, 3, 7],
          aug:    [0, 4, 8],
          dim:    [0, 3, 6]
      },
      7 => {
          major_minor:  [0, 4, 7, 10],
          major:        [0, 4, 7, 11],
          minor_major:  [0, 3, 7, 11],
          minor_minor:  [0, 3, 7, 10],
          aug:          [0, 4, 8, 11]
      }
  }

  class ChordHarmonics
    attr_reader :notes
    ##
    # def initialize(chord_name_n, root_note_name, inversion, length, strength, type)
    #   type =
    #       :white, use white keys to play the harmonics
    #       for triads, :major, :minor, :aug, :dim
    #       for 7 chords, besides, :major_minor, :minor_major
    def initialize(n, base, length, inversion = 0, strength = 127, type = :white)
      root = NotePitch.new(base)
      chord_counts = CHORD_COUNTS[n]
      @notes = []
      if type == :white
        chord_counts.times do |i|
          @notes << Note.new(
              root.next_white(2 * i).midi + ((0...inversion).include?(i) ? HALF_NOTES_PER_SCALE : 0),
              length,
              strength)
        end
      else
        chord_counts.times do |i|
          @notes << Note.new(
              root.midi + CHORD_TABLE[n][type][i] + ((0...inversion).include?(i) ? HALF_NOTES_PER_SCALE : 0),
              length,
              strength)
        end
      end

      Note.new(root, length, strength)
    end

    def to_s
      ret = ''
      @notes.each do |note|
        ret += note.to_s + ' '
      end
      ret
    end
  end
end