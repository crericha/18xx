# frozen_string_literal: true

require './spec/spec_helper'

describe 'progress bar timelines' do
  def current_label(file, action_id)
    data = JSON.parse(File.read(File.join(FIXTURES_DIR, file)))
    game = Engine::Game.load(data, at_action: action_id)
    cell = game.game_timeline.current_cell
    cell && "#{cell.label}|#{cell.value}"
  end

  {
    '1840/218809.json' => { 1 => 'PRE|', 77 => 'CR 1|1x', 116 => 'LR 1a|' },
    '18MS/14375.json' => { 414 => 'OR 9|', 460 => 'End|' },
  }.each do |file, expectations|
    expectations.each do |action_id, expected|
      it "#{file} at action #{action_id} highlights #{expected}" do
        expect(current_label(file, action_id)).to eq(expected)
      end
    end
  end

  {
    Engine::Game::G1840::Game => 24,
    Engine::Game::G18CZ::Game => 30,
    Engine::Game::G18MS::Game => 20,
    Engine::Game::G18ZOOMapA::Game => 12,
    Engine::Game::G21Moon::Game => 23,
    Engine::Game::G22Mars::Game => 18,
    Engine::Game::GSteamOverHolland::Game => 17,
  }.each do |klass, cells|
    it "#{klass.title} shows a single-row timeline of #{cells} cells" do
      game = klass.new(%w[a b c])
      expect(game.show_progress_bar?).to be(true)
      expect(game.game_timeline.rows.size).to eq(1)
      expect(game.game_timeline.width).to eq(cells)
    end
  end

  it '18MS adds OR 11 with the or_11 optional rule' do
    game = Engine::Game::G18MS::Game.new(%w[a b c], optional_rules: [:or_11])
    expect(game.game_timeline.rows[0].map(&:label)).to include('OR 11')
  end

  it '18ZOO keeps its uncolored END cell' do
    game = Engine::Game::G18ZOOMapA::Game.new(%w[a b c])
    last = game.game_timeline.rows[0].last
    expect([last.label, last.value, last.color]).to eq(['END', '20', nil])
  end

  it '22Mars updates revolt markers after the revolt' do
    game = Engine::Game::G22Mars::Game.new(%w[a b c])
    before = game.game_timeline
    expect(before.rows[0].find { |c| c.label == 'OR 7' }.value).to eq('✘/✔')

    game.revolt!
    after = game.game_timeline
    revolt_round = game.instance_variable_get(:@revolt_round)

    expect(after).not_to equal(before)
    expect(after.rows[0].find { |c| c.label == "OR #{revolt_round}" }.value).to eq('✔')
  end
end
