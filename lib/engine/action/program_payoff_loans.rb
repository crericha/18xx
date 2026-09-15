# frozen_string_literal: true

require_relative 'base'
require_relative 'program_enable'

module Engine
  module Action
    class ProgramPayoffLoans < ProgramEnable
      def to_s
        'Pay off loans in Stock Round'
      end

      def disable?(game)
        !game.round.stock?
      end
    end
  end
end
