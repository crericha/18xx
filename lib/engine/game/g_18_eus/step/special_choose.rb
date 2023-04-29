# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialChoose < Engine::Step::SpecialChoose
          def actions(entity)
            return [] if entity.owner != current_entity
            return [] if entity == @game.late_bloomer && @game.turn < 4

            super
          end

          def process_choose_ability(action)
            entity = action.entity

            case entity
            when @game.late_bloomer
              process_late_bloomer_choose_ability(ability)
            when @game.reappraisal
              increase_share_price(entity.owner)
            when @game.bank_reappraisal
              increase_share_price(@game.bny)
            end

            entity.close!
          end

          def process_late_bloomer_choose_ability(action)
            entity = action.entity
            if (private = @game.late_bloomer_companies.find { |c| c.name == action.choice })
              @game.companies << private
              private.owner = entity.owner
              entity.owner.companies << private
            else
              @game.bank.spend(@game.class::LATE_BLOOMER_CASH, entity.owner)
            end

            @log << "#{entity.owner.name} swaps #{entity.name} for #{action.choice}"
          end

          def increase_share_price(entity)
            old_price = entity.share_price
            @game.stock_market.move_right(entity)
            @game.log_share_price(entity, old_price, 1)
          end
        end
      end
    end
  end
end
