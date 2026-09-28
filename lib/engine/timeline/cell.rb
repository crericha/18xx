# frozen_string_literal: true

module Engine
  class Timeline
    class Cell
      attr_reader :type, :label, :value, :color, :icon

      def initialize(type: nil, label: nil, value: nil, color: nil, icon: nil, step: nil, defaults: nil)
        defaults ||= {}
        @type = type
        @label = label || defaults[:label] || type.to_s
        @value = value
        @color = color || defaults[:color]
        @icon = icon || defaults[:icon]
        @step = step.nil? ? defaults.fetch(:step, true) : step
      end

      def step?
        @step
      end

      def info?
        @type == :Info
      end

      def header?
        @type == :Header
      end
    end
  end
end
