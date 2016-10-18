require_relative '../note'
include Musel
RSpec.describe ChordHarmonics do
  it 'should create triads' do
    c5_3 = ChordHarmonics.new(3, :c5, 1)
    expect(c5_3.to_s.strip).to eq('C5 E5 G5')
  end

end
