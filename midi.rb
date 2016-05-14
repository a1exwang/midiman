require 'midilib'
require 'pp'

module Musel
  class Midi

    module Instruments
      ACOUSTIC_PIANO =  'Acoustic Grand Piano'
      BRIGHT_PIANO =    'Bright Acoustic Piano'
      MUSIC_BOX =       'Music Box'
      CHURCH_ORGAN =    'Church Organ'
      ACOUSTIC_GUITAR_NYLON = 'Acoustic Guitar (nylon)'
      VIOLIN =          'Violin'
      VIOLA =           'Viola'
      CELLO =           'Cello'
      PICCOLO =         'Piccolo'
      FLUTE =           'Flute'
    end

    def initialize(name, bpm, instrument)
      @seq = MIDI::Sequence.new
      tempo_track = MIDI::Track.new(@seq)
      @seq.tracks << tempo_track
      tempo_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(bpm), 0)
      tempo_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, name)

      @main_track = MIDI::Track.new(@seq)
      @seq.tracks << @main_track
      @main_track.name = 'Main'

      @main_track.events << MIDI::ProgramChange.new(0, 1, 0)
      @main_track.instrument = instrument

      @start_time = 0
    end

    def insert_note(pitch, start_time, length, strength = 127)
      on = MIDI::NoteOn.new(0, pitch, strength, 0)
      on.time_from_start = start_time
      off = MIDI::NoteOff.new(0, pitch, strength, length)
      off.time_from_start = start_time + length
      @main_track.events << on << off
    end

    def append_note(pitch, length, strength = 127)
      on = MIDI::NoteOn.new(0, pitch, strength, 0)
      on.time_from_start = @start_time
      off = MIDI::NoteOff.new(0, pitch, strength, length)
      off.time_from_start = @start_time + length
      @main_track.events << on << off
      @start_time += length
    end

    def append_harmonics(pitches, length, strength = 127)
      pitches.each do |pitch|
        on = MIDI::NoteOn.new(0, pitch, strength, 0)
        on.time_from_start = @start_time
        off = MIDI::NoteOff.new(0, pitch, strength, length)
        off.time_from_start = @start_time + length
        @main_track.events << on << off
      end
      @start_time += length
    end

    def append_harm(harm)
      duration = 0
      harm.notes.each do |note|
        duration = note_to_delta(note.duration.name)
        on = MIDI::NoteOn.new(0, note.pitch.midi, note.strength, 0)
        on.time_from_start = @start_time
        off = MIDI::NoteOff.new(0, note.pitch.midi, note.strength, duration)
        off.time_from_start = @start_time + duration
        @main_track.events << on << off
      end
      @start_time += duration
    end

    def note_to_delta(name)
      @seq.note_to_delta(name)
    end

    def save_to(file_name)
      @main_track.recalc_delta_from_times
      File.open(file_name, 'wb') { | file | @seq.write(file) }
    end

  end
end