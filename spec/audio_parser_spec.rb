require_relative '../parse_notes'
require 'pp'

include Musel::AudioParser
RSpec.describe Musel::AudioParser do
  it 'should parse a simple sine sequence' do
    sample_rate = 44100.0
    t = 1.0
    freq1 = 440.0
    sample_count = sample_rate * t
    na_10sin_44100 = sine_narray(sample_count, t, freq1, 0)

    white_noise = 0.01
    notes = parse_notes(na_10sin_44100, sample_rate, t, white_noise)
    predict_notes = notes.reject { |_, val| val <= 0 }.sort_by { |_, val| -val }

    expect(predict_notes.first.first).to eq(69)
  end
  it 'should parse Asin(at + p1) + Bsin(bt + p1)' do
    sample_rate = 44100.0
    t = 1.0
    freq1 = 440.0
    freq2 = 261.63 # C4
    sample_count = sample_rate * t
    na_10sin_3sin = sine_narray(sample_count, t, freq1, freq2, 10, 3)

    white_noise = 0.01
    notes = parse_notes(na_10sin_3sin, sample_rate, t, white_noise)
    predict_notes = notes.reject { |_, val| val <= 0 }.sort_by { |_, val| -val }

    expect(predict_notes[0].first).to eq(69)
    expect(predict_notes[1].first).to eq(60)
  end

  it 'should use Gauss windowing function' do
    sample_rate = 44100.0
    t = 1.0
    freq1 = 440.0
    freq2 = 261.63 # C4
    sample_count = sample_rate * t
    na_10sin_3sin = sine_narray(sample_count, t, freq1, freq2, 10, 3)

    white_noise = 0.01
    notes = parse_notes(na_10sin_3sin, sample_rate, t, white_noise, make_gauss_windowing_function(0.25))
    predict_notes = notes.reject { |_, val| val <= 0 }.sort_by { |_, val| -val }

    expect(predict_notes[0].first).to eq(69)
    expect(predict_notes[1].first).to eq(60)
  end

  it 'should parse wave file of one onte' do
    result = parse_file('test/append-note.wav')
    # pp result
  end

end