# frozen_string_literal: true

require_relative '../../../step/special_token'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialToken < Engine::Step::SpecialToken
          def available_hex(entity, hex)
            return c0_available_hex(entity, hex) if entity.id == 'C0'

            super
          end

          def c0_available_hex(entity, hex)
            !hex.tile.cities.empty? &&
              !hex.tile.cities.first.tokened_by?(entity.owner) &&
              @game.graph.reachable_hexes(entity.owner).include?(hex)
          end

          def process_place_token(action)
            super

            entity = action.entity
            @game.log << "#{entity.name} closes"
            entity.close!
          end

          def ability(entity)
            return unless entity&.company?

            possible_times = [
              '%current_step%',
            ]

            @game.abilities(entity, :token, time: possible_times)
          end
        end
      end
    end
  end
end
