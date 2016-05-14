require 'midilib'

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
      tempo_track = Track.new(@seq)
      @seq.tracks << tempo_track
      tempo_track.events << Tempo.new(Tempo.bpm_to_mpq(bpm), 0)
      tempo_track.events << MetaEvent.new(META_SEQ_NAME, name)

      @main_track = Track.new(@seq)
      seq.tracks << @main_track
      @main_track.name = 'Main'

      @main_track.events << ProgramChange.new(0, 1, 0)
      @main_track.instrument = instrument

      @start_time = 0
    end

    def insert_note(pitch, start_time, length, strength = 127)
      on = NoteOn.new(0, pitch, strength, 0)
      on.time_from_start = start_time
      off = NoteOff.new(0, pitch, strength, length)
      off.time_from_start = start_time + length
      @main_track.events << on << off
    end

    def append_note(pitch, length, strength = 127)
      on = NoteOn.new(0, pitch, strength, 0)
      on.time_from_start = @start_time
      off = NoteOff.new(0, pitch, strength, length)
      off.time_from_start = @start_time + length
      @main_track.events << on << off
    end

    def append_harmonics(pitches, length, strength = 127)
      pitches.each do |pitch|
        on = NoteOn.new(0, pitch, strength, 0)
        on.time_from_start = @start_time
        off = NoteOff.new(0, pitch, strength, length)
        off.time_from_start = @start_time + length
        @main_track.events << on << off
      end
    end

    def save_to(file_name)
      @main_track.recalc_delta_from_times
      File.open(file_name, 'wb') { | file | @seq.write(file) }
    end

  end
end