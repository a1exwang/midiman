require 'pp'
require_relative 'note'
require_relative 'midi'
require_relative 'pattern'
include Musel

midi = Midi.new('Alex MIDI', 60, Musel::Midi::Instruments::ACOUSTIC_PIANO)

# 1645
# Musel::Pattern.harm_1645(midi, 3)
# Musel::Pattern.harm_1645(midi, 3)
# Musel::Pattern.harm_1645(midi, 3)
# Musel::Pattern.harm_1645(midi, 3)

Musel::Pattern.pachelbel_canon(midi, 3)
Musel::Pattern.pachelbel_canon(midi, 3)
# scale 3
# (1..7).each do |i|
#   2.times { append_triad(track, ('cdefgab'[i-1] + '3').to_sym, quarter_note_length) }
# end

# triads
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :major) }
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :minor) }
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :aug) }
# 2.times { append_triad(track, :g3, quarter_note_length, 0, :dim) }

## 7 chords
# @chord_table[7].keys.each do |key|
#   2.times { chord_n(midi, 7, :g3, quarter_note_length, 0, key) }
# end

midi.save_to('my_output_file.mid')

`timidity --output-24bit -A120 my_output_file.mid -Ow`

# to play, use
# ffplay -nodisp -autoexit my_output_file.wav