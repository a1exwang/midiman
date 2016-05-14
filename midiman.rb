require 'midilib'
require 'pp'
include MIDI
include Musel
require_relative 'note_pitch'
require_relative 'midi'


def chord_harmonics(midi, count, base, start_time, length, strength = 127)
  n_base = NotePitch.new(base.to_s)
  pitches = []
  count.times do |i|
    pitches << yield(n_base, i)
  end
  midi.append_harmonics(pitches, start_time, length, strength)
end

@chord_counts = {
    3 => 3,
    7 => 4
}
@chord_table = {
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
def triad(midi, base, start_time, length, var = 0, type = :white, strength = 127)
  if type == :white
    chord_harmonics(midi, 3, base, start_time, length, strength) do |n_base, i|
      n_base.next_white(2 * i).midi +
          (((var == 1 && i == 0) || (var == 2 && (i == 0 || i == 1))) ? HALVES_PER_SCALE : 0)
    end
  else
    chord_harmonics(midi, 3, base, start_time, length, strength) do |n_base, i|
      [
          n_base.midi + @chord_table[3][type][0] + ([1, 2].include?(var) ? HALVES_PER_SCALE : 0),
          n_base.midi + @chord_table[3][type][1] + ((1 == var) ? HALVES_PER_SCALE : 0),
          n_base.midi + @chord_table[3][type][2]
      ][i]
    end
  end
end

def chord_n(midi, n, base, start_time, length, var = 0, type = :white ,strength = 127)
  chord_counts = @chord_counts[n]
  if type == :white
    chord_harmonics(midi, chord_counts, base, start_time, length, strength) do |n_base, i|
      n_base.next_white(2 * i).midi +
          ((1..(chord_counts-1-i)).include?(var) ? HALVES_PER_SCALE : 0)
    end
  else
    chord_harmonics(midi, chord_counts, base, start_time, length, strength) do |n_base, i|
      n_base.midi + @chord_table[n][type][i] +
          ((1..(chord_counts-1-i)).include?(var) ? HALVES_PER_SCALE : 0)
    end
  end
end

midi = Musel::Midi.new('Alex MIDI', 60, Musel::Midi::Instruments::ACOUSTIC_PIANO)
quarter_note_length = seq.note_to_delta('quarter')

def append_triad(track, pitch, length, var = 0, type = :white, strength = 127)
  triad(midi, pitch, @current_position, length, var, type, strength)
end
def append_chord_n(track, n, pitch, length, var = 0, type = :white, strength = 127)
  chord_n(midi, n, pitch, @current_position, length, var, type, strength)
end

# 1645
# 2.times { append_triad(track, :c4, quarter_note_length) }
# 2.times { append_triad(track, :a3, quarter_note_length) }
# 2.times { append_triad(track, :f3, quarter_note_length, 1) }
# 2.times { append_triad(track, :g3, quarter_note_length, 1) }

# scale 3
# (1..7).each do |i|
#   2.times { append_triad(track, ('cdefgab'[i-1] + '3').to_sym, quarter_note_length) }
# end

# triads
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :major) }
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :minor) }
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :aug) }
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :dim) }

# 7 chords
@chord_table[7].keys.each do |key|
  2.times { append_chord_n(track, 7, :g3, quarter_note_length, 0, key) }
end

File.open('my_output_file.mid', 'wb') { | file | seq.write(file) }

`timidity --output-24bit -A120 my_output_file.mid -Ow`

# to play, use
# ffplay -nodisp -autoexit my_output_file.wav