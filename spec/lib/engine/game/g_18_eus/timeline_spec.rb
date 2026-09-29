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

    def step_row
      timeline.rows.find { |r| r.any? { |c| timeline.current?(c) } }
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
        [['8', nil, :light_blue], ['SR3', nil, :dark_purple], ['OR3.1', nil, :pure_white], ['', nil, :pure_white],
         ['OR3.2', nil, :pure_white], ['', nil, :pure_white]],
        [['10', nil, :light_blue], ['SR4+', nil, :dark_purple], ['OR 1', nil, :pure_white], ['', nil, :pure_white],
         ['OR 2', nil, :pure_white], ['', nil, :pure_white]],
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
      expect(timeline.current_cell.label).to eq('OR3.1')
      expect(timeline.current_cell).to equal(timeline.rows[3][2])
      expect(step_row.select { |c| timeline.current?(c) }).to eq([timeline.current_cell])
    end

    [4, 5, 9].each do |turn|
      it "reuses the SR4+ row in turn #{turn}" do
        game.instance_variable_set(:@round_counter, 50)
        put_in(turn: turn, round: :stock)
        expect(timeline.current_cell.label).to eq('SR4+')
        expect(timeline.current_cell).to equal(timeline.rows[4][1])
        expect(step_row.select { |c| timeline.current?(c) }).to eq([timeline.current_cell])

        put_in(turn: turn, round: :operating, round_num: 2)
        expect(timeline.current_cell.label).to eq('OR 2')
        expect(timeline.current_cell).to equal(timeline.rows[4][4])
      end
    end

    it 'moves to the SR END row once the end set starts' do
      game.instance_variable_set(:@round_counter, 60)
      put_in(turn: 7, round: :stock, end_set: true)
      expect(timeline.current_cell.label).to eq('SR END')
      expect(timeline.current_cell).to equal(timeline.rows[5][1])
      expect(step_row.select { |c| timeline.current?(c) }).to eq([timeline.current_cell])

      put_in(turn: 7, round: :final_build, end_set: true)
      expect(timeline.current_cell.label).to eq('Final Build')
      expect(timeline.current_cell).to equal(timeline.rows[5][2])

      put_in(turn: 7, round: :operating, round_num: 3, end_set: true)
      expect(timeline.current_cell.label).to eq('OR 3')
      expect(timeline.current_cell).to equal(timeline.rows[5][5])
    end

    it 'uses the SR END row even if the end set starts before turn 4' do
      put_in(turn: 3, round: :operating, round_num: 1, end_set: true)
      expect(timeline.current_cell).to equal(timeline.rows[5][3])
    end

    it 'wraps the row 0 labels but not others' do
      expect(timeline.rows[0][0].wrap?).to be(true)
      expect(timeline.rows[0][1].wrap?).to be(true)
      expect(timeline.rows[1][1].wrap?).to be(false)
    end

    it 'wraps Max Loans, Initial Auction, No Export, and Final Build' do
      expect(timeline.rows[0][0].wrap?).to be(true) # Max Loans
      expect(timeline.rows[0][1].wrap?).to be(true) # Initial Auction
      expect(timeline.rows[2][3].wrap?).to be(true) # No Export
      expect(timeline.rows[5][2].wrap?).to be(true) # Final Build
      expect(timeline.rows[1][1].wrap?).to be(false) # SR1
    end

    it 'shows hover text only on the cells the round table calls out' do
      expected = [
        [0, 1, 'A Privates'],
        [1, 1, 'Auction for starting locations'],
        [1, 3, 'Export all 2 trains'],
        [1, 5, 'Export all 2+ trains'],
        [2, 1, 'B Privates'],
        [2, 3, 'No train export'],
        [2, 5, 'Export all 3 trains'],
        [3, 1, 'C Privates'],
        [4, 5, 'If 4D bought or exported, proceed to SR END'],
        [5, 1, 'No force-buy, no starting companies'],
        [5, 2, 'Each corporation gets 2 tile lays'],
      ]

      actual = timeline.rows.each_with_index.flat_map do |row, r|
        row.each_with_index.filter_map { |cell, c| [r, c, cell.hover] if cell.hover }
      end
      expect(actual).to eq(expected)

      hover_coords = expected.map { |r, c, _| [r, c] }
      timeline.rows.each_with_index do |row, r|
        row.each_with_index do |cell, c|
          expect(cell.hover).to be_nil unless hover_coords.include?([r, c])
        end
      end
    end

    it 'uses a 5em cell width' do
      expect(game.timeline_cell_width).to eq('5em')
    end
  end
end
