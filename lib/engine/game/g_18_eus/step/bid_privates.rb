# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'
require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Step
        class BidPrivates < Engine::Step::BuySellParShares
          include BidboxAuction

          def actions(entity)
            return [] if entity != current_entity

            super
          end

          def hide_corporations?
            true
          end

          def can_buy_any?(_entity)
            false
          end

          def can_ipo_any?(_entity)
            false
          end

          def may_purchase?(_entity)
            false
          end

          def may_choose?(_entity)
            false
          end

          def available
            @game.bidbox_privates
          end

          def description
            'Initial Auction'
          end

          def process_pass(action)
            entity = action.entity

            @log << "#{entity.name} passes bidding"
            entity.pass! if @bid_actions.zero?
            pass!
          end

          def pass!
            if @bid_actions.positive?
              @round.pass_order.delete(current_entity)
            else
              @round.pass_order |= [current_entity]
            end
            super
          end
        end
      end
    end
  end
end
