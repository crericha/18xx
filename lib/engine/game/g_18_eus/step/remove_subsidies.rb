# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Step
        module RemoveSubsidies
          def lay_tile(action, extra_cost: 0, entity: nil, spender: nil)
            super
            @game.remove_subsidy(action.hex) if action.tile.color == :yellow
          end
        end
      end
    end
  end
end
