# frozen_string_literal: true

require_relative '../../../step/special_token'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialToken < Engine::Step::SpecialToken
          def available_hex(entity, hex)
            return c0_available_hex(entity, hex) if entity.id == 'C0'
            return s6_available_hex(entity, hex) if entity.id == 'S6'

            super
          end

          def c0_available_hex(entity, hex)
            # TODO: doesn't work with NYC's multiple cities
            !hex.tile.cities.empty? &&
              !hex.tile.cities.first.tokened_by?(entity.owner) &&
              hex.tile.cities.first.tokens.none? { |t| t.type == :neutral } &&
              @game.graph.reachable_hexes(entity.owner).include?(hex)
          end

          def s6_available_hex(entity, hex)
            # TODO: doesn't work with NYC's multiple cities
            !hex.tile.cities.empty? &&
              hex.tile.cities.first.tokenable?(entity.owner) &&
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

            if (ability = @game.abilities(entity, :token, time: possible_times)) &&
                @game.token_graph_for_entity(entity.owner).can_token?(entity.owner, cheater: ability.cheater)
              return ability
            end

            nil
          end
        end
      end
    end
  end
end
