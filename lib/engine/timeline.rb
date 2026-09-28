# frozen_string_literal: true

require_relative 'timeline/cell'

module Engine
  class Timeline
    attr_reader :rows

    def initialize(rows, game)
      @game = game
      types = game.timeline_types
      @rows = rows.map do |row|
        row.map { |cell| Cell.new(**cell, defaults: types[cell[:type]]) }
      end
      @steps = @rows.flat_map { |row| row.select(&:step?) }
    end

    def width
      @rows.map(&:size).max || 0
    end

    def row_start_step(row_index)
      @rows.take(row_index).sum { |row| row.count(&:step?) }
    end

    def current_cell
      step = @game.timeline_step
      return nil if !step || step.negative?

      @steps[step]
    end

    def current?(cell)
      current = current_cell
      !current.nil? && cell.equal?(current)
    end
  end
end
