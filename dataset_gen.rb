require_relative 'midi'
require_relative 'parse_notes'
require 'json'

def gen_single_note(count, note_count, bpm, dir, file_prefix, to_wav = true, wav_sample_rate = 44100)
  count.times do |i|
    composer = MidiComposer.new('Test MIDI', bpm)
    piano = composer.create_track('Piano', MidiComposer::Instruments::ACOUSTIC_PIANO)
    note_count.times do
      midi_val = (48..96).to_a.sample
      piano.append_note(Note.new(midi_val, 1))
    end
    wav_filepath = File.join(dir, "#{file_prefix}_#{note_count}notes_#{bpm}bpm_#{wav_sample_rate}Hz_%08x.wav" % [i])
    midi_filepath = File.join(dir, "#{file_prefix}_#{note_count}notes_#{bpm}bpm_%08x.midi" % [i])
    composer.save_to(midi_filepath)
    if to_wav
      `timidity --output-24bit -A120 #{midi_filepath} -Ow #{wav_filepath}`
    end
  end
end

include Musel
include Musel::AudioParser
def gen_onte_note_train_test_data(count, bpm, dir, dataset_json_file)
  `mkdir -p #{dir}`
  bps = bpm / 60.0
  sec_per_beat = 1 / bps

  # Given parameters
  min_note_count = 1
  max_note_count = 4
  sample_rate = 44100
  window_duration = sec_per_beat / 2.0
  window_interval = sec_per_beat / 8.0
  lowest_freq = 20
  highest_freq = 2000

  min_midi_val = 48
  max_midi_val = 96

  # Calculated parameters
  base_freq = 1.0 / window_duration
  # window_count = (1 / window_interval).round

  lowest_freq_index = (lowest_freq / base_freq).round
  highest_freq_index = (highest_freq / base_freq).round
  freq_count = highest_freq_index - lowest_freq_index

  # valid_beats = 1
  # valid_count = (valid_beats * bps / window_duration).floor
  valid_count = 8

  output_json = {
      rows: valid_count,
      cols: freq_count,
      data: [],
      labels: []
  }

  count.times do |i|
    # Generate a random number of random notes
    note_count = (min_note_count..max_note_count).to_a.sample
    midi_vals = Array.new(note_count) { (min_midi_val...max_midi_val).to_a.sample }

    composer = MidiComposer.new('Test MIDI', bpm)
    piano = composer.create_track('Piano', MidiComposer::Instruments::ACOUSTIC_PIANO)

    label = Array.new(max_midi_val - min_midi_val) { 0 }
    midi_vals.each do |midi_val|
      piano.insert_note(Note.new(midi_val, 1), 0, 0)
      label[midi_val - min_midi_val] = 1
    end

    file_prefix = 'test-one-note'
    wav_filepath = File.join(dir, "#{file_prefix}_#{bpm}bpm_#{i}.wav")
    midi_filepath = File.join(dir, "#{file_prefix}_#{bpm}bpm_#{i}.midi")
    composer.save_to(midi_filepath)
    `timidity --output-24bit -A120 #{midi_filepath} -Ow #{wav_filepath} --sampling-freq=#{sample_rate}`
    result = parse_file(wav_filepath, :raw, window_duration, window_interval, 0, 1)

    data = result[:data]
    float_data  = []
    data.first(valid_count).each_with_index do |da, _|
      # da is [time, freq_spectrum]
      freq_spectrum = da[1]
      float_data << freq_spectrum[lowest_freq_index...highest_freq_index].to_a.map{|x| x.magnitude}
    end
    output_json[:data] << float_data
    output_json[:labels] << label
  end

  File.write(dataset_json_file, output_json.to_json)
end

def wav_to_json(wav_file, bpm, output_json_file)
  sec_per_beat = 60.0 / bpm
  window_duration = sec_per_beat / 2.0
  window_interval = sec_per_beat / 8.0
  base_freq = 1.0 / window_duration

  lowest_freq = 20.0
  highest_freq = 2000.0
  lowest_freq_index = (lowest_freq / base_freq).round
  highest_freq_index = (highest_freq / base_freq).round

  bps = 60.0 / bpm
  valid_beats = 1
  valid_count = (valid_beats * bps / window_interval).floor

  result = parse_file(wav_file, :raw, window_duration, window_interval)

  data = result[:data]
  json = []
  data.first(valid_count).each_with_index do |da, _|
    # da is [time, freq_spectrum]
    freq_spectrum = da[1]
    byte_data = freq_spectrum[lowest_freq_index...highest_freq_index].to_a.map{|x| (x.magnitude * 256).to_i}
    json << byte_data
  end

  File.write(output_json_file, json.to_json)
end

# gen_onte_note_train_test_data(30, 60, 'test/dataset', 'test/dataset.db', 'test/dataset-label.json')
# wav_to_json('test/append-chords.wav', 60, 'test/append-chords.json')

if ARGV.size == 0
  STDERR.puts 'wrong argument'
  exit(1)
end

case ARGV[0]
when 'train'
  n = ARGV[1].to_i
  output_file = ARGV[2]
  tmp_dir = ARGV[3]
  gen_onte_note_train_test_data(n, 60, tmp_dir, output_file)
when 'play'
  wav_file = ARGV[1]
  json_file = ARGV[2]
  wav_to_json(wav_file, 60, json_file)
else
  STDERR.puts 'wrong argument'
  exit(1)
end
