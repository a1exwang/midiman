require 'midilib'
require 'pp'
include MIDI

def note(pitch, start_time, length, strength = 127)
  on = NoteOn.new(0, pitch, strength, 0)
  on.time_from_start = start_time
  off = NoteOff.new(0, pitch, strength, length)
  off.time_from_start = start_time + length
  [on, off]
end

def note_pitch_nnn_white(c, n, sharp = 0)
  n_arr = [0, 2, 4, 5, 7, 9, 11]
  12 * n + 12 + n_arr[c] + sharp
end
def note_pitch(name)
  raise "unknown note #{name}" unless name.to_s =~ /^([a-z])([0-8])([#b]?)$/i
  c = ($1.unpack('c').first - 'a'.unpack('c').first - 2 + 7) % 7
  n = $2.to_i
  if $3 == '#'
    sharp = 1
  elsif $3 == 'b'
    sharp = -1
  else
    sharp = 0
  end
  note_pitch_nnn_white(c, n, sharp)
end

def triad_major(base, start_time, length, var = 0, strength = 127)
  n_base = note_pitch(base)
  note(n_base, start_time, length, strength) +
      note(n_base + 4, start_time, length, strength) +
      note(n_base + 7, start_time, length, strength)
end

@parameters = {
    bpm:              60,
    sequence_name:    'Alex MIDI File',
    main_instrument:  GM_PATCH_NAMES[0], # Acoustic piano
}

seq = Sequence.new
tempo_track =Track.new(seq)
seq.tracks << tempo_track
tempo_track.events << Tempo.new(Tempo.bpm_to_mpq(@parameters[:bpm]), 0)
tempo_track.events << MetaEvent.new(META_SEQ_NAME, @parameters[:sequence_name])

track = Track.new(seq)
seq.tracks << track
track.name = 'Main Piano'

track.events << ProgramChange.new(0, 1, 0)
quarter_note_length = seq.note_to_delta('quarter')
track.instrument = @parameters[:main_instrument]


4.times do |i|
  track.events += triad_major(:c4, quarter_note_length*2 * (1+i), quarter_note_length)
end

track.recalc_delta_from_times
File.open('my_output_file.mid', 'wb') { | file | seq.write(file) }

`timidity --output-24bit -A120 my_output_file.mid -Ow`