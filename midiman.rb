require 'midilib'
require 'pp'
include MIDI
N_ARR = [0, 2, 4, 5, 7, 9, 11]
HALF_PER_SCALE = 12

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
      self.midi = HALF_PER_SCALE * (self.scale + 1) + N_ARR[c] + self.sharp_b
    else
      self.note = 0
      self.scale = 3
      self.sharp_b = 0
      self.midi = 48
    end
  end

  def self.from_midi(midi_n)
    scale = midi_n / HALF_PER_SCALE - 1
    note = midi_n % HALF_PER_SCALE
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

  def next_white
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
  end

  def to_s
    s = 'cdefgab'
    sb = [nil, '#', 'b']
    "#{s[self.note]}#{self.scale}#{sb[self.sharp_b]}"
  end
end

def note(pitch, start_time, length, strength = 127)
  on = NoteOn.new(0, pitch, strength, 0)
  on.time_from_start = start_time
  off = NoteOff.new(0, pitch, strength, length)
  off.time_from_start = start_time + length
  [on, off]
end

def triad_major(base, start_time, length, var = 0, strength = 127)
  n_base = NotePitch.new(base.to_s)
  note(n_base.midi, start_time, length, strength) +
      note(n_base.midi + 4, start_time, length, strength) +
      note(n_base.midi + 7, start_time, length, strength)
end
def triad_minor(base, start_time, length, var = 0, strength = 127)
  n_base = NotePitch.new(base.to_s)
  note(n_base.midi, start_time, length, strength) +
      note(n_base.midi + 3, start_time, length, strength) +
      note(n_base.midi + 7, start_time, length, strength)
end
def triad(base, start_time, length, var = 0, strength = 127)
  n_base = NotePitch.new(base.to_s)
  r1 = n_base.next_white.next_white
  r2 = r1.next_white.next_white
  note(n_base.midi, start_time, length, strength) +
      note(r1.midi, start_time, length, strength) +
      note(r2.midi, start_time, length, strength)
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

@current_position = 0
def append_triad_major(track, pitch, length)
  track.events += triad_major(pitch, @current_position, length)
  @current_position += length
end
def append_triad_minor(track, pitch, length)
  track.events += triad_minor(pitch, @current_position, length)
  @current_position += length
end
def append_triad(track, pitch, length)
  track.events += triad(pitch, @current_position, length)
  @current_position += length
end

2.times { append_triad(track, :c4, quarter_note_length) }
2.times { append_triad(track, :a3, quarter_note_length) }
2.times { append_triad(track, :f3, quarter_note_length) }
2.times { append_triad(track, :g3, quarter_note_length) }

track.recalc_delta_from_times
File.open('my_output_file.mid', 'wb') { | file | seq.write(file) }

`timidity --output-24bit -A120 my_output_file.mid -Ow`

# to play, use
# ffplay -nodisp -autoexit my_output_file.wav