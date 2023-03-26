# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialChoose < Engine::Step::SpecialChoose
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
              entity.owner.companies << private
            else
              @game.bank.spend(@game.class::LATE_BLOOMER_CASH, entity.owner)
            end

            @log << "#{entity.owner.name} swaps #{entity.name} for #{action.choice}"
            entity.close!
          end
        end
      end
    end
  end
end
