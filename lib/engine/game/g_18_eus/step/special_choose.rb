# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialChoose < Engine::Step::Base
          def actions(entity)
            return [] if entity.owner != current_entity

            super
          end

          def active?
            @game.turn >= 4
          end

          def process_choose_ability(action)
            entity = action.entity

            if (private = @game.late_bloomer_companies.find { |c| c.name == action.choice })
              @game.companies << private
              private.owner = entity.owner
              entity.owner << private
            else
              @game.bank.spend(@game.LATE_BLOOMER_CASH, entity.owner)
            end

            @log << "#{entity.name} swapped for #{action.choice}"
            entity.close!
          end
        end
      end
    end
  end
end
