# frozen_string_literal: true

require 'spec_helper'

describe Engine::Game::G18EUS::Game do
  describe 'timeline' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:timeline) { game.timeline_grid }

    def put_in(turn:, round:, round_num: 1, end_set: false)
      game.instance_variable_set(:@turn, turn)
      game.instance_variable_set(:@end_set, end_set)
      fake = case round
             when :stock then double('stock round', stock?: true, operating?: false)
             when :operating then double('operating round', stock?: false, operating?: true, round_num: round_num)
             when :final_build then Engine::Game::G18EUS::Round::FinalBuild.allocate
             end
      game.instance_variable_set(:@round, fake)
    end

    def current_row_labels
      row = timeline.rows.find { |r| r.any? { |c| timeline.current?(c) && c.step? } }
      row.select { |c| timeline.current?(c) }.map(&:label)
    end

    it 'is shown as a 6-column grid of 6 rows' do
      expect(game.show_progress_bar?).to be(true)
      expect(timeline.rows.size).to eq(6)
      expect(timeline.width).to eq(6)
    end

    it 'matches the round table labels and colors' do
      expect(timeline.rows.map { |r| r.map { |c| [c.label, c.value, c.color] } }).to eq([
        [['Max Loans', nil, :light_blue], ['Initial Auction', nil, :red]],
        [['4', nil, :light_blue], ['SR1', nil, :yellow], ['OR1.1', nil, :yellow], ['', '2', :yellow],
         ['OR1.2', nil, :yellow], ['', '2+', :yellow]],
        [['6', nil, :light_blue], ['SR2', nil, :light_blue], ['OR2.1', nil, :green], ['No Export', nil, :green],
         ['OR2.2', nil, :green], ['', '3', :green]],
        [['8', nil, :light_blue], ['SR3', nil, :dark_purple], ['OR3.1', nil, nil], ['', nil, nil],
         ['OR3.2', nil, nil], ['', nil, nil]],
        [['10', nil, :light_blue], ['SR4+', nil, :dark_purple], ['OR 1', nil, nil], ['', nil, nil],
         ['OR 2', nil, nil], ['', nil, nil]],
        [['10', nil, :light_blue], ['SR END', nil, :brown], ['Final Build', nil, :brown], ['OR 1', nil, :brown],
         ['OR 2', nil, :brown], ['OR 3', nil, :brown]],
      ])
    end

    it 'shows the train export icon on export cells but not on No Export' do
      icons = timeline.rows[2].map(&:icon)
      expect(icons).to eq([nil, nil, nil, nil, nil, 'train_export'])
      expect(timeline.rows[3][3].icon).to eq('train_export')
    end

    it 'keeps only the footnote as timeline text' do
      expect(game.timeline).to eq(['*Exported trains are removed from the game and can trigger phase changes ' \
                                   'as if purchased'])
    end

    it 'highlights the initial auction at the start of the game' do
      expect(timeline.current_cell.label).to eq('Initial Auction')
      expect(timeline.current?(timeline.rows[0][0])).to be(false)
    end

    it 'follows round_counter through the first three sets' do
      game.instance_variable_set(:@round_counter, 8)
      put_in(turn: 3, round: :operating, round_num: 1)
      expect(current_row_labels).to eq(%w[8 OR3.1])
    end

    [4, 5, 9].each do |turn|
      it "reuses the SR4+ row in turn #{turn}" do
        game.instance_variable_set(:@round_counter, 50)
        put_in(turn: turn, round: :stock)
        expect(current_row_labels).to eq(%w[10 SR4+])

        put_in(turn: turn, round: :operating, round_num: 2)
        expect(current_row_labels).to eq(['10', 'OR 2'])
      end
    end

    it 'moves to the SR END row once the end set starts' do
      game.instance_variable_set(:@round_counter, 60)
      put_in(turn: 7, round: :stock, end_set: true)
      expect(current_row_labels).to eq(['10', 'SR END'])

      put_in(turn: 7, round: :final_build, end_set: true)
      expect(current_row_labels).to eq(['10', 'Final Build'])

      put_in(turn: 7, round: :operating, round_num: 3, end_set: true)
      expect(current_row_labels).to eq(['10', 'OR 3'])
      expect(timeline.current_cell).to equal(timeline.rows[5][5])
    end

    it 'uses the SR END row even if the end set starts before turn 4' do
      put_in(turn: 3, round: :operating, round_num: 1, end_set: true)
      expect(timeline.current_cell).to equal(timeline.rows[5][3])
    end
  end
end
