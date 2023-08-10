# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Step
        module ScenicRouteNotUpgradeable
          def lay_tile(action, extra_cost: 0, entity: nil, spender: nil)
            hex = action.hex
            raise GameError, 'Cannot upgrade Scenic Route' if hex.assigned?('plus_20') && hex.tile.cities.empty?

            super
          end
        end
      end
    end
  end
end
