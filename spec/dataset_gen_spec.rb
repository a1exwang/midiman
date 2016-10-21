require_relative '../dataset_gen'

RSpec.describe 'DatasetGenerator' do
  it 'should generate single notes' do
    gen_single_note(5, 8, 120, 'test/dataset', 'single-note')
  end
end
