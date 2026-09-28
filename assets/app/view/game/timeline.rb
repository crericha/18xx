# frozen_string_literal: true

require 'lib/settings'

module View
  module Game
    class Timeline < Snabberb::Component
      include Lib::Settings

      needs :game

      def render
        timeline = @game.timeline_grid
        cells = timeline.rows.flat_map do |row|
          row.map { |cell| render_cell(cell, timeline.current?(cell)) } +
            Array.new(timeline.width - row.size) { render_blank }
        end

        h(:div, {
            style: {
              display: 'grid',
              gridTemplateColumns: "repeat(#{timeline.width}, min-content)",
              justifyContent: 'start',
              overflowX: 'auto',
            },
          }, cells)
      end

      private

      def render_cell(cell, current)
        children =
          if cell.label.empty?
            [cell.value ? h(:div, cell.value) : nil, render_icon(cell.icon)].compact
          else
            label = cell.wrap? ? h(:div, cell.label) : h('div.nowrap', cell.label)
            [cell.value ? h('div.center', cell.value) : nil, render_icon(cell.icon), label].compact
          end

        h(:div, cell_props(cell, current), children)
      end

      def render_icon(icon)
        return nil unless icon

        h(:div, [h(:img, { attrs: { src: "/icons/#{icon}.svg", width: '15px' } })])
      end

      def render_blank
        h(:div, cell_props(nil, false))
      end

      def justify_content(cell)
        return 'center' if cell&.icon && cell.label.empty?
        return 'space-between' if cell&.value || cell&.icon

        'flex-end'
      end

      def cell_props(cell, current)
        bg_color, font_color =
          if cell&.color
            [color_for(cell.color), contrast_on(color_for(cell.color))]
          else
            [color_for(:bg2), color_for(:font2)]
          end

        props = {
          style: {
            display: 'flex',
            flexDirection: 'column',
            boxSizing: 'border-box',
            height: '3.5em',
            padding: '4px',
            border: '1px solid rgba(0,0,0,0.2)',
            justifyContent: justify_content(cell),
            backgroundColor: bg_color,
            color: font_color,
          },
        }
        if current
          props[:style].merge!(
            fontWeight: 'bold',
            border: "4px solid #{color_for(:red)}",
            padding: '1px 4px',
          )
        end

        props
      end
    end
  end
end
