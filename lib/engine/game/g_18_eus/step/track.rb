# frozen_string_literal: true

require_relative '../../../step/track'
require_relative 'tracker'
require_relative 'skip_bny'
require_relative 'remove_subsidies'

module Engine
  module Game
    module G18EUS
      module Step
        class Track < Engine::Step::Track
          include SkipBny
          include RemoveSubsidies

          def process_lay_tile(action)
            return super unless free_home_city_lay?(action.entity, action.hex)

            lay_tile(action)
            @round.laid_hexes << action.hex
          end

          def free_home_city_lay?(corp, hex)
            !corp.operated? && corp.tokens.first&.hex == hex
          end
        end
      end
    end
  end
end
