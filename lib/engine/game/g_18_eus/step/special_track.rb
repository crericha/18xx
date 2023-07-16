# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative 'remove_subsidies'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          include RemoveSubsidies

          def available_hex(entity, hex)
            if @game.rural_junction_companies.include?(entity) &&
               ((hex.tile.color != :white) || !hex.tile.labels.empty? || hex.tile.cities.any?(&:tokened?))
              return false
            end
            if entity == scenic_route
              return hex.tile.color == :white && hex.tile.cities.empty? && @game.graph.connected_hexes(entity.owner).include?(hex)
            end

            super
          end

          def potential_tile_colors(entity, _hex)
            colors = super
            colors << :green if entity.id == 'S9'
            colors
          end

          def hex_neighbors(entity, hex)
            return super unless entity == scenic_route

            owner = entity.owner
            @game.graph_for_entity(owner).connected_hexes(owner)[hex]
          end

          def process_lay_tile(action)
            tile = action.tile
            company = action.entity
            owner = company.owner

            super

            if company == scenic_route
              tile.hex.assign!('plus_20')
              @game.log << "#{owner.name} adds +20 token to #{tile.hex.name}"
            end
            return unless @game.rural_junction_companies.include?(company)

            abilities(company) do |ability|
              next unless ability.type == :tile_lay

              ability.tiles.delete(tile.name)
            end
          end

          def scenic_route
            @scenic_route ||= @game.company_by_id('A5')
          end
        end
      end
    end
  end
end
