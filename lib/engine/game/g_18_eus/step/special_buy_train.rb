# frozen_string_literal: true

require_relative '../../../step/special_buy_train'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialBuyTrain < Engine::Step::SpecialBuyTrain
          def ability(entity, train: nil)
            ability = super
            return ability if !ability || entity != @game.rust_insurance

            corp = entity.owner
            return nil if !must_buy_train?(corp) || needed_cash(corp) <= corp.cash

            emr_cash = needed_cash(corp) - corp.cash
            ability.discount = (emr_cash / 2.0).floor
            ability
          end
        end
      end
    end
  end
end
