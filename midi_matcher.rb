require 'midilib'
require 'pp'
require_relative 'midi'
require_relative 'note'

module Musel
  class MidiMatcher
    def initialize(file_name)
      @seq = MIDI::Sequence.new
      File.open(file_name, 'rb') do | file |
        @seq.read(file)
      end

      @sharpflat = 0
      @bpm = @seq.bpm

      @note_starts = Array.new(@seq.tracks.size) { Hash.new { |hash, key| hash[key] = [] } }

      @seq.tracks.each_with_index do |track, i|
        track.events.each do |event|
          case event
            when MIDI::NoteOn
              @note_starts[i][[event.time_from_start, event.off.time_from_start]] << event
            when MIDI::NoteOff
            when MIDI::Tempo
            when MIDI::TimeSig
            when MIDI::Controller
            when MIDI::KeySig
              @sharpflat = event.sharpflat
            when MIDI::MetaEvent
            else
              pp event
              puts event.to_s
          end
        end
      end

      @time_strings = {}

      @note_starts.each do |track|
        track.each do |time, notes|
          if notes.size >= 3
            chords = []
            names = []
            notes.each do |note|
              n = Musel::Note.new(note.note-2, 1000, note.velocity)
              chords << n.pitch.note
              names << n.to_s
            end
            new_chords = chords.sort.uniq
            root = new_chords.first
            new_chords.map! { |x| x - root }
            if new_chords.size >= 2
              sec_time = (@seq.pulses_to_seconds(time.first).round(1)..@seq.pulses_to_seconds(time.last).round(1))
              str = "#{sec_time}\t" + names.join(' ') + "\t"
              if new_chords.size == 2
                [
                    'unison', 'minor 2', 'major 2', 'minor 3', 'major 3',
                    'perfect 4', 'dim 5', 'perfect 5', 'minor 6', 'major 6',
                    'minor 7', 'major 7', 'octave'
                ][new_chords[1]] || new_chords[1]
              elsif new_chords.size == 3
                case new_chords[1..2]
                  when [4, 7]
                    str += 'triads major'
                  when [3, 8]
                    str += 'triads major inversion 1'
                  when [5, 9]
                    str += 'triads major inversion 2'
                  when [3, 7]
                    str += 'triads minor'
                  when [4, 9]
                    str += 'triads minor inversion 1'
                  when [5, 8]
                    str += 'triads minor inversion 2'
                  else
                    str += new_chords.join(' ')
                end
              else  # new_chords.size > 3
              end
              str += "\n"
              puts str
              @time_strings[sec_time] = str
            end
          end
        end
      end

      @section_ticks = @seq.length_to_delta(@seq.numer)
      @sections = split_into_sections(@note_starts, @section_ticks)
    end

    def split_into_sections(note_starts, section_duration)
      sections = []
      note_starts.each_with_index do |track, index|
        sections << []
        track.each do |time, notes|
          musel_notes = []
          notes.each do |note|
            n = Musel::Note.new(note.note-2, 1000, note.velocity)
            musel_notes << n
          end

          s1 = time.min / section_duration
          s2 = time.max / section_duration
          if s1 == s2 || (s1 + 1 == s2 && time.max % section_duration == 0)
            sections[index][s1] = (sections[index][s1] || []) + musel_notes
            #puts "section #{s1}\t#{musel_notes.map {|x|x.to_s}.join(' ')}"
          else
            puts "#{time}\t#{musel_notes.map{|x| x.to_s}.join(' ')}"
          end
        end
        sections[index].each_with_index do |section_notes, i|
          if section_notes
            puts "section #{i}\t#{section_notes.map {|x|x.to_s}.join(' ')}"
          else
            sections[index][i] = []
          end
        end
      end
      sections
    end

    def play_sync
      #`timidity --output-24bit -A120 midis/canon_dmajor.mid -Ow -o canon.wav`
      Thread.new { `ffplay -nodisp -autoexit -v quiet midis/#{ARGV[0]}.wav` }
      start_time = Time.now
      current_section = 0
      loop do
        sleep(0.01)
        t = Time.now - start_time
        # if t > @time_strings.first.first.min
        #   puts @time_strings.first.last
        #   @time_strings.delete(@time_strings.first.first)
        # end
        if current_section < 0 || t > @seq.pulses_to_seconds(@section_ticks * current_section)
          @sections.each do |track|
            if track[current_section]&.size > 0
              printf "time: %0.2f, section: %d, %s\n", t, current_section, track[current_section].map(&:to_s).join(' ')
            end
          end
          current_section += 1
        end

      end
    end
  end
end


m = Musel::MidiMatcher.new("midis/#{ARGV[0]}.mid")
m.play_sync