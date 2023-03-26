# frozen_string_literal: true

require_relative '../../../step/assign'

module Engine
  module Game
    module G18EUS
      module Step
        class Assign < Engine::Step::Assign
          def process_assign(action)
            return super unless action.entity == 'A8'

            company = action.entity
            hex = action.target

            validate_offboard_assignment(hex, company.owner)
            hex.tile.nodes.first.parse_revenue(@game.class::P6_REVENUE_MARKER)
            @log << "#{company.owner.name} (#{company.id}) assigns 40/60/80/100 value token to #{hex.id} (#{hex.location_name})"

            company.close!
            @log << "#{company.name} closes"
          end

          def validate_offboard_assignment(hex, corporation)
            raise GameError, "#{hex.name} not an offboard location" if hex.tile.color != :red
            raise GameError, "#{corporation.name} not connected to #{hex.name}" if !@game.loading &&
                                                                                   !connected_to_hex?(corporation, hex)
          end

          def available_hex(entity, hex)
            return connected_to_hex?(entity.owner, hex) && hex.tile.color == :red if entity.id == 'A8'

            super
          end

          def connected_to_hex?(entity, hex)
            @game.graph.reachable_hexes(entity)[hex]
          end
        end
      end
    end
  end
end
