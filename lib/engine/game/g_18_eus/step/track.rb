# frozen_string_literal: true

require_relative '../../../step/track'
require_relative 'skip_bny'
require_relative 'remove_subsidies'
require_relative 'skip_end_set'
require_relative 'scenic_route_not_upgradeable'

module Engine
  module Game
    module G18EUS
      module Step
        class Track < Engine::Step::Track
          include SkipBny
          include SkipEndSet
          include RemoveSubsidies
          include ScenicRouteNotUpgradeable

          def process_lay_tile(action)
            return super unless free_home_city_lay?(action.entity, action.hex)

            lay_tile(action)
            @round.laid_hexes << action.hex
          end

          def free_home_city_lay?(corp, hex)
            !corp.operated? && corp.tokens.first&.hex == hex && !@round.laid_hexes.include?(hex)
          end
        end
      end
    end
  end
end
