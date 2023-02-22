# frozen_string_literal: true

require_relative '../../../step/tracker'

module Engine
  module Game
    module G18EUS
      module Tracker
        include Engine::Step::Tracker

        def lay_tile(action, extra_cost: 0, entity: nil, spender: nil)
          super
          @game.remove_subsidy(action.hex) if action.tile.color == :yellow
        end
      end
    end
  end
end
