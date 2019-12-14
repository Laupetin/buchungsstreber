require 'yaml'

RSpec.describe 'CLI App', type: :aruba do
  let(:config_file) { expand_path('~/.config/buchungsstreber/config.yml') }
  let(:entry_file) { expand_path('~/.config/buchungsstreber/buchungen.yml') }
  let(:archive_path) { expand_path('~/.config/buchungsstreber/archive') }
  let(:example_file) { File.expand_path('../example.buchungen.yml', __dir__) }

  context 'Aruba' do
    it { expect(aruba).to be }
  end

  context 'Unconfigured buchungsstreber' do
    it 'runs version command' do
      run_command('buchungsstreber version')
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/\d+\.\d+/)
    end

    it 'runs init command' do
      run_command('buchungsstreber init')
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/erstellt/)
      expect(config_file).to be_an_existing_file
    end
  end

  context 'Configured buchungsstreber' do
    before(:each) do
      run_command('buchungsstreber init')
      expect(last_command_started).to be_successfully_executed

      # Make sure the api-keys are set
      set_environment_variable('EDITOR', 'ed')
      c = run_command('buchungsstreber config')
      c.write(',/apikey:.*/apikey: anything/')
      c.write(',/url:.*/url: http:\/\/localhost\/')
      c.write('w')
      c.write('q')
      expect(c).to be_successfully_executed

      set_environment_variable('EDITOR', 'cat')
    end

    it 'does not allow a second run to init' do
      run_command('buchungsstreber init')
      expect(last_command_started).to have_output(/bereits konfiguriert/)
    end

    it 'runs config command' do
      run_command('buchungsstreber config')
      expect(last_command_started).to have_output(/^timesheet_file:/)
      expect(last_command_started).to have_output(/^url: htt/)
      expect(last_command_started).to have_output(/^apikey: anything/)
      expect(last_command_started).to be_successfully_executed
    end

    it 'runs edit command' do
      FileUtils.copy(example_file, entry_file)
      run_command('buchungsstreber edit')
      expect(last_command_started).to have_output(/BeispielDaily/)
      expect(last_command_started).to be_successfully_executed
    end

    it 'adds times to redmine' do
      c = run_command('buchungsstreber')
      c.write('y')
      expect(c).to have_output(/BeispasdfasdfasdfielDaily/)
      expect(a_request(:post, "localhost").
        with(body: "abc", headers: {'Content-Length' => 3})).
        to have_been_made.once

    end
  end
end
