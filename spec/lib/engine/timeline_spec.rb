# frozen_string_literal: true

require './spec/spec_helper'

module Engine
  describe Timeline do
    let(:step) { 0 }
    let(:game) { double('game', timeline_step: step) }
    let(:types) { Engine::Game::Base::TIMELINE_TYPES }
    let(:rows) do
      [
        [{ type: :Info, label: 'Max Loans' }, { type: :PRE }],
        [{ type: :Info, label: '4' }, { type: :SR, label: 'SR 1' }, { type: :OR, label: 'OR 1.1', value: '40' },
         { type: :Export, value: '2+' }, { type: :OR, label: 'OR 1.2', color: :brown }],
      ]
    end
    let(:timeline) { described_class.new(rows, types, game) }

    def cell(label)
      timeline.rows.flatten.find { |c| c.label == label }
    end

    describe 'cell defaults' do
      it 'uses the type table when the cell does not set a value' do
        sr = cell('SR 1')
        expect(sr.color).to eq(:green)
        expect(sr.step?).to be(true)
      end

      it 'prefers values set on the cell over the type table' do
        expect(cell('OR 1.2').color).to eq(:brown)
      end

      it 'falls back to neutral defaults for unknown types' do
        or11 = cell('OR 1.1')
        expect(or11.color).to be_nil
        expect(or11.icon).to be_nil
        expect(or11.value).to eq('40')
        expect(or11.step?).to be(true)
      end

      it 'defaults the label to the type name' do
        expect(timeline.rows[0][1].label).to eq('PRE')
      end

      it 'gives Export cells the train icon, no label, yellow, and no step' do
        export = timeline.rows[1][3]
        expect(export.label).to eq('')
        expect(export.icon).to eq('train_export')
        expect(export.color).to eq(:yellow)
        expect(export.value).to eq('2+')
        expect(export.step?).to be(false)
      end

      it 'lets a type table entry with color: nil remove the default color' do
        uncolored = types.merge(Export: types[:Export].merge(color: nil))
        export = described_class.new(rows, uncolored, game).rows[1][3]
        expect(export.color).to be_nil
        expect(export.icon).to eq('train_export')
      end

      it 'does not count Info cells as steps' do
        expect(cell('4').step?).to be(false)
        expect(cell('Max Loans').step?).to be(false)
      end

      it 'defaults wrap? to false' do
        expect(cell('4').wrap?).to be(false)
      end

      it 'honors an explicit wrap: true on a cell' do
        rows = [[{ type: :Info, label: 'Max Loans', wrap: true }, { type: :PRE }]]
        wrapped = described_class.new(rows, types, game)
        expect(wrapped.rows[0][0].wrap?).to be(true)
      end

      it 'honors wrap: true from the type table' do
        wrapping = types.merge(Info: types[:Info].merge(wrap: true))
        expect(described_class.new(rows, wrapping, game).rows[1][0].wrap?).to be(true)
      end

      it 'defaults hover to nil' do
        expect(cell('OR 1.1').hover).to be_nil
      end

      it 'keeps an explicit hover: on a cell' do
        rows = [[{ type: :Info, label: 'Max Loans', hover: 'tooltip text' }, { type: :PRE }]]
        with_hover = described_class.new(rows, types, game)
        expect(with_hover.rows[0][0].hover).to eq('tooltip text')
      end

      it 'uses a type table hover when the cell has none' do
        hovering = types.merge(Info: types[:Info].merge(hover: 'info tip'))
        expect(described_class.new(rows, hovering, game).rows[1][0].hover).to eq('info tip')
      end
    end

    describe '#width' do
      it 'is the length of the longest row' do
        expect(timeline.width).to eq(5)
      end

      it 'is 0 with no rows' do
        expect(described_class.new([], types, game).width).to eq(0)
      end
    end

    describe '#row_start_step' do
      it 'counts step cells in earlier rows' do
        expect(timeline.row_start_step(0)).to eq(0)
        expect(timeline.row_start_step(1)).to eq(1)
      end
    end

    describe 'current step' do
      context 'when timeline_step is 0' do
        it 'highlights the first step cell and not the Info cell in its row' do
          expect(timeline.current_cell.label).to eq('PRE')
          expect(timeline.current?(cell('PRE'))).to be(true)
          expect(timeline.current?(cell('Max Loans'))).to be(false)
          expect(timeline.current?(cell('4'))).to be(false)
        end
      end

      context 'when timeline_step is 3' do
        let(:step) { 3 }

        it 'skips non-step cells when counting' do
          expect(timeline.current_cell.label).to eq('OR 1.2')
        end

        it 'never highlights the Info cell, only the step cell, in the current row' do
          expect(timeline.current?(cell('4'))).to be(false)
          expect(timeline.rows.flatten.select { |c| timeline.current?(c) }).to eq([cell('OR 1.2')])
        end
      end

      [99, -1, nil].each do |out_of_range|
        context "when timeline_step is #{out_of_range.inspect}" do
          let(:step) { out_of_range }

          it 'highlights nothing' do
            expect(timeline.current_cell).to be_nil
            expect(timeline.rows.flatten.none? { |c| timeline.current?(c) }).to be(true)
          end
        end
      end
    end

    describe 'Base#game_timeline' do
      let(:real_game) { Engine::Game::G1889::Game.new(%w[a b]) }

      it 'is built once and memoized' do
        expect(real_game.game_timeline).to equal(real_game.game_timeline)
      end

      it 'is empty by default and uses round_counter as the step' do
        expect(real_game.game_timeline.rows).to eq([])
        expect(real_game.timeline_step).to eq(real_game.round_counter)
        expect(real_game.show_progress_bar?).to be(false)
      end
    end
  end
end
