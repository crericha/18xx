# frozen_string_literal: true

require_relative '../../../round/operating'

module Engine
  module Game
    module G18EUS
      module Round
        class Operating < Engine::Round::Operating
          def next_entity!
            entity = @entities[@entity_index]
            if (subsidy = entity.companies.find { |c| c == @game.increase_stock_price_subsidy })
              @game.log << "#{subsidy.name} subsidy increases #{entity.name}'s stock price"
              old_price = entity.share_price
              @game.stock_market.move_right(entity)
              @game.log_share_price(entity, old_price)
              subsidy.close!
            end

            super
          end
        end
      end
    end
  end
end
