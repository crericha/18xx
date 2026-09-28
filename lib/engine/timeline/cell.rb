# frozen_string_literal: true

module Engine
  class Timeline
    class Cell
      attr_reader :type, :label, :value, :color, :icon

      def initialize(type: nil, label: nil, value: nil, color: nil, icon: nil, step: nil, wrap: nil, defaults: nil)
        defaults ||= {}
        @type = type
        @label = label || defaults[:label] || type.to_s
        @value = value
        @color = color || defaults[:color]
        @icon = icon || defaults[:icon]
        @step = step.nil? ? defaults.fetch(:step, true) : step
        @wrap = wrap.nil? ? defaults.fetch(:wrap, false) : wrap
      end

      def step?
        @step
      end

      def wrap?
        @wrap
      end
    end
  end
end
