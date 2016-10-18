require 'midilib'
require 'pp'

module Musel
  class MidiTrack
    attr_reader :bpm, :numer, :denom
    def initialize(seq, name, instrument)
      @seq = seq
      @numer = seq.numer
      @denom = seq.denom
      @bpm = seq.beats_per_minute

      @main_track = MIDI::Track.new(@seq)
      @seq.tracks << @main_track
      @main_track.name = name

      @main_track.events << MIDI::ProgramChange.new(0, 1, 0)
      @main_track.instrument = instrument

      @start_time = 0
    end
    def sections_to_delta(section, beat)
      @seq.length_to_delta(section * @numer + beat)
    end
    def beats_to_delta(beats)
      @seq.length_to_delta(beats)
    end

    ##
    # MidiComposer#insert_note
    # @param note: Note object, representing the note pitch, strength, length etc.
    # @param section: indicating the position of the note
    # @param beat: indicating the position of the note
    # The note is inserted at section +section+, beat +beat+, both starting from 0.
    # e.g
    # insert_note(Note.new(:a4, 3/2r, 127), 0, 2)
    def insert_note(note, section, beat)
      start = self.sections_to_delta(section, beat)
      insert_note_at_beat(note, start)
    end
    def insert_note_at_beat(note, beat)
      self.insert_raw_note(
          note.pitch.midi,
          self.beats_to_delta(beat),
          self.beats_to_delta(note.duration.beats),
          note.strength)
    end

    ##
    # MidiComposer#append_note
    # @param note: Note object
    def append_note(note)
      self.insert_raw_note(
          note.pitch.midi,
          self.beats_to_delta(@start_time),
          self.beats_to_delta(note.duration.beats),
          note.strength)
      @start_time += note.duration.beats
    end

    def insert_raw_note(pitch, start_time, length, strength = 127)
      on = MIDI::NoteOn.new(0, pitch, strength, 0)
      on.time_from_start = start_time
      off = MIDI::NoteOff.new(0, pitch, strength, length)
      off.time_from_start = start_time + length
      @main_track.events << on << off
    end

    def append_chords(chords)
      max_duration = 0
      chords.notes.each do |note|
        max_duration = note.duration.beats if note.duration.beats > max_duration
        insert_note_at_beat(note, @start_time)
      end
      @start_time += max_duration
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

  end

  class MidiComposer

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

    attr_reader :bpm, :numer, :denom
    def initialize(name, bpm = 60, numer = 4, denom = 4)
      @numer = numer
      @denom = denom
      @bpm = bpm
      @seq = MIDI::Sequence.new
      @seq.numer = @numer
      @seq.denom = @denom
      tempo_track = MIDI::Track.new(@seq)
      @seq.tracks << tempo_track
      tempo_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(bpm), 0)
      tempo_track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, name)
      @tracks = []
    end

    def create_track(name, instrument)
      track = MidiTrack.new(@seq, name, instrument)
      @tracks << track
      track
    end

    def save_to(file_name)
      @seq.tracks.each do |t|
        t.recalc_delta_from_times
      end
      File.open(file_name, 'wb') { | file | @seq.write(file) }
    end

  end
end