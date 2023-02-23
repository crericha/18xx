# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'
require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Step
        class BuySellParShares < Engine::Step::BuySellParShares
          include Parrer
          include BidboxAuction

          PURCHASE_ACTIONS = (Engine::Step::BuySellParShares::PURCHASE_ACTIONS + [Engine::Action::TakeLoan,
                                                                                  Engine::Action::Convert]).freeze

          def actions(entity)
            return corporation_actions(entity) if entity.corporation? && entity.owned_by?(current_entity)

            super
          end

          def corporation_actions(entity)
            return [] if bought? || !can_convert?(entity)

            %w[convert pass]
          end

          def can_convert?(corporation)
            corporation.total_shares == 5
          end

          def process_convert(action)
            corporation = action.entity
            raise GameError, "Cannot act for another player's corporation" unless corporation.owned_by?(current_entity)

            @game.grow_corporation(corporation)
            track_action(action, corporation)
          end

          def can_buy_multiple?(_entity, corporation, owner)
            super || (@round.current_actions.any? { |a| a.is_a?(Action::Convert) && a.entity == corporation } &&
              @round.current_actions.count { |a| a.is_a?(Action::BuyShares) && a.bundle.corporation == corporation } < 3)
          end
        end
      end
    end
  end
end
