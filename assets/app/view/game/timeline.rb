# frozen_string_literal: true

require 'lib/settings'

module View
  module Game
    class Timeline < Snabberb::Component
      include Lib::Settings

      needs :game

      ROW_END_RADIUS = '10px'

      def render
        timeline = @game.timeline_grid
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
                gridTemplateColumns: "repeat(#{timeline.width}, #{@game.timeline_cell_width || 'min-content'})",
                gap: '2px',
                justifyContent: 'start',
                filter: 'drop-shadow(0 1px 1px rgba(0,0,0,0.15))',
              },
            }, cells),
        ])
      end

      private

      def render_cell(cell, current, row_index, column_index, row_size)
        children =
          if cell.label.empty?
            [cell.value ? h(:div, cell.value) : nil, render_icon(cell.icon)].compact
          else
            label = cell.wrap? ? h(:div, cell.label) : h('div.nowrap', cell.label)
            [cell.value ? h('div.center', cell.value) : nil, render_icon(cell.icon), label].compact
          end

        props = { style: cell_style(cell, current, row_index, column_index, row_size) }
        props[:attrs] = { title: cell.hover } if cell.hover

        h(:div, props, children)
      end

      def render_icon(icon)
        return nil unless icon

        h(:div, [h(:img, { attrs: { src: "/icons/#{icon}.svg", width: '15px' } })])
      end

      def justify_content(cell)
        return 'center' if cell.icon && cell.label.empty?
        return 'space-between' if cell.value || cell.icon

        'flex-end'
      end

      def cell_style(cell, current, row_index, column_index, row_size)
        bg_color, font_color =
          if cell.color
            [color_for(cell.color), contrast_on(color_for(cell.color))]
          else
            [color_for(:bg2), color_for(:font2)]
          end

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
          justifyContent: justify_content(cell),
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
