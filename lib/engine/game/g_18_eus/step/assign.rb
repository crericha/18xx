# frozen_string_literal: true

require_relative '../../../step/assign'

module Engine
  module Game
    module G18EUS
      module Step
        class Assign < Engine::Step::Assign
          def process_assign(action)
            company = action.entity
            hex = action.target

            case company
            when goldrush_railway
              validate_offboard_assignment(hex, company.owner)
              hex.tile.nodes.first.parse_revenue(@game.class::A8_REVENUE_MARKER)
              @log << "#{company.owner.name} (#{company.id}) changes value of #{hex.id} (#{hex.location_name}) to 40/60/80/100"

              company.close!
              @log << "#{company.name} closes"
            when boomtown
              if !@game.loading && !available_hex(company, hex)
                raise GameError, "Cannot assign #{company.name} to #{hex.name} (#{hex.location_name})"
              end

              hex.assign!('plus_20')
              @log << "#{company.name} assigned to #{hex.name} (#{hex.location_name})"

              company.close!
              @log << "#{company.name} closes"
            else
              super
            end
          end

          def validate_offboard_assignment(hex, corporation)
            raise GameError, "#{hex.name} not an offboard location" if hex.tile.color != :red
            raise GameError, "#{corporation.name} not connected to #{hex.name}" if !@game.loading &&
                                                                                   !connected_to_hex?(corporation, hex)
          end

          def available_hex(entity, hex)
            return connected_to_hex?(entity.owner, hex) && hex.tile.color == :red if entity == goldrush_railway

            if entity == boomtown
              return connected_to_hex?(entity.owner, hex) &&
                !hex.tile.cities.empty? &&
                hex.tile.labels.empty?
            end

            super
          end

          def connected_to_hex?(entity, hex)
            @game.graph.reachable_hexes(entity)[hex]
          end

          def goldrush_railway
            @goldrush ||= @game.company_by_id('A8')
          end

          def boomtown
            @boomtown ||= @game.company_by_id('B2')
          end
        end
      end
    end
  end
end
