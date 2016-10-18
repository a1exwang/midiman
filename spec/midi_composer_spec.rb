require_relative '../midi'
require_relative '../note'

include Musel
RSpec.describe MidiComposer do
  it 'should generate single notes' do
    composer = MidiComposer.new('Test MIDI', 60)
    piano = composer.create_track('Piano', MidiComposer::Instruments::ACOUSTIC_PIANO)
    # Insert a note A4 at section 0, beat 0, length 1.5 beats
    piano.insert_note(Note.new(:c5, 1), 0, 0)
    piano.insert_note(Note.new(:g4, 1), 0, 1)
    piano.insert_note(Note.new(:a4, 1), 0, 2)
    piano.insert_note(Note.new(:e4, 1), 0, 3)
    composer.save_to('test/single-notes.midi')
  end

  it 'should append single notes' do
    composer = MidiComposer.new('Test MIDI', 60)
    piano = composer.create_track('Piano', MidiComposer::Instruments::ACOUSTIC_PIANO)
    # Insert a note A4 at section 0, beat 0, length 1.5 beats
    piano.append_note(Note.new(:c5, 1))
    piano.append_note(Note.new(:g4, 1))
    piano.append_note(Note.new(:a4, 1))
    piano.append_note(Note.new(:e4, 1))
    composer.save_to('test/append-note.midi')
  end

  it 'should append chords' do
    composer = MidiComposer.new('Test MIDI', 60)
    piano = composer.create_track('Piano', MidiComposer::Instruments::ACOUSTIC_PIANO)
    # Insert a note A4 at section 0, beat 0, length 1.5 beats
    piano.append_chords(ChordHarmonics.new(3, :c5, 1))
    piano.append_chords(ChordHarmonics.new(3, :g4, 1))
    piano.append_chords(ChordHarmonics.new(3, :a4, 1))
    piano.append_chords(ChordHarmonics.new(3, :e4, 1))
    composer.save_to('test/append-chords.midi')
  end

  it 'should create multiple tracks' do
    composer = MidiComposer.new('Test MIDI', 60)
    cello = composer.create_track('Cello', MidiComposer::Instruments::CELLO)
    violin = composer.create_track('Violin', MidiComposer::Instruments::VIOLIN)
    # Insert a note A4 at section 0, beat 0, length 1.5 beats
    cello.append_chords(ChordHarmonics.new(3, :c4, 2))
    cello.append_chords(ChordHarmonics.new(3, :g3, 2))
    cello.append_chords(ChordHarmonics.new(3, :a3, 2))
    cello.append_chords(ChordHarmonics.new(3, :e3, 2))
    cello.append_chords(ChordHarmonics.new(3, :f3, 2))
    cello.append_chords(ChordHarmonics.new(3, :c3, 2))
    cello.append_chords(ChordHarmonics.new(3, :f3, 2))
    cello.append_chords(ChordHarmonics.new(3, :g3, 2))

    violin.append_note(Note.new(:e6, 2))
    violin.append_note(Note.new(:d6, 2))
    violin.append_note(Note.new(:c6, 2))
    violin.append_note(Note.new(:b5, 2))
    violin.append_note(Note.new(:a5, 2))
    violin.append_note(Note.new(:g5, 2))
    violin.append_note(Note.new(:a5, 2))
    violin.append_note(Note.new(:b5, 2))
    composer.save_to('test/multiple-tracks.midi')
  end
end
