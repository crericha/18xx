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

            super
          end

          def potential_tile_colors(entity, _hex)
            colors = super
            colors << :green if entity.id == 'S9'
            colors
          end
        end
      end
    end
  end
end
