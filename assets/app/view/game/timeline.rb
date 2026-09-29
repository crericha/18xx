# frozen_string_literal: true

require 'lib/settings'

module View
  module Game
    class Timeline < Snabberb::Component
      include Lib::Settings

      needs :game

      ROW_END_RADIUS = '10px'

      # timeline-only colors: not tile colors, so they stay out of Lib::Hex::COLOR
      COLORS = {
        light_blue: '#9FC5E8',
        dark_purple: '#674EA7',
        pure_white: '#FFFFFF',
      }.freeze

      def render
        timeline = @game.game_timeline
        cells = timeline.rows.each_with_index.flat_map do |row, row_index|
          row.each_with_index.map do |cell, column_index|
            render_cell(cell, timeline.current?(cell), row_index, column_index, row.size)
          end
        end

        # padding keeps the current-cell ring from being clipped by the scroll container
        h(:div, { style: { overflowX: 'auto', padding: '3px' } }, [
          h(:div, {
              style: {
                display: 'grid',
                # equal columns, each as wide as the widest cell in the whole timeline: under a
                # max-content constraint every 1fr track takes the largest max-content contribution
                width: 'max-content',
                gridTemplateColumns: "repeat(#{timeline.width}, 1fr)",
                gap: '2px',
                filter: 'drop-shadow(0 1px 1px rgba(0,0,0,0.15))',
              },
            }, cells),
        ])
      end

      private

      def render_cell(cell, current, row_index, column_index, row_size)
        children =
          if cell.label.empty?
            # icon and value (e.g. the exported train) share one line
            [h(:div, { style: { display: 'flex', alignItems: 'center', gap: '3px' } },
               [render_icon(cell.icon), cell.value ? h(:div, cell.value) : nil].compact)]
          else
            [cell.value ? h(:div, cell.value) : nil, render_icon(cell.icon), render_label(cell)].compact
          end

        props = { style: cell_style(cell, current, row_index, column_index, row_size) }
        props[:attrs] = { title: cell.hover } if cell.hover

        h(:div, props, children)
      end

      def render_icon(icon)
        return nil unless icon

        h(:div, { style: { display: 'flex' } }, [h(:img, { attrs: { src: "/icons/#{icon}.svg", width: '15px' } })])
      end

      # a wrapped label is centered as a block whose lines share one left edge; min-content also
      # keeps it from widening its column to the full text
      def render_label(cell)
        return h('div.nowrap', cell.label) unless cell.wrap?

        h(:div, { style: { width: 'min-content', textAlign: 'left' } }, cell.label)
      end

      # a themeable palette color, else one of this component's own colors
      def cell_color(name)
        color_for(name) || COLORS[name]
      end

      def cell_style(cell, current, row_index, column_index, row_size)
        bg = cell.color && cell_color(cell.color)
        bg_color, font_color = bg ? [bg, contrast_on(bg)] : [color_for(:bg2), color_for(:font2)]

        style = {
          # rows can be shorter than the grid, so place every cell explicitly
          gridRow: row_index + 1,
          gridColumn: column_index + 1,
          display: 'flex',
          flexDirection: 'column',
          boxSizing: 'border-box',
          height: '3.5em',
          padding: '4px 6px',
          border: '1px solid rgba(0,0,0,0.06)',
          justifyContent: 'center',
          alignItems: 'center',
          textAlign: 'center',
          backgroundColor: bg_color,
          color: font_color,
        }
        style[:cursor] = 'help' if cell.hover
        style.merge!(current_style(cell)) if current
        if column_index.zero?
          style[:borderTopLeftRadius] = ROW_END_RADIUS
          style[:borderBottomLeftRadius] = ROW_END_RADIUS
        end
        if column_index == row_size - 1
          style[:borderTopRightRadius] = ROW_END_RADIUS
          style[:borderBottomRightRadius] = ROW_END_RADIUS
        end

        style
      end

      # a ring straddling the cell edge; red cells get a font-colored ring so it stays visible
      def current_style(cell)
        ring_color = cell.color == :red ? color_for(:font) : color_for(:red)
        {
          fontWeight: 'bold',
          outline: "4px solid #{ring_color}",
          outlineOffset: '-2px',
          borderRadius: '3px',
          position: 'relative',
          zIndex: 1,
        }
      end
    end
  end
end
