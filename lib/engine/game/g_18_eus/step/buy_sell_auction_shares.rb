# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'
require_relative 'parrer'
require_relative 'bidbox_auction'
require_relative 'loan_taker'
require_relative 'corp_auction'

module Engine
  module Game
    module G18EUS
      module Step
        class BuySellAuctionShares < Engine::Step::BuySellParShares
          include LoanTaker
          include CorpAuction

          PURCHASE_ACTIONS = (Engine::Step::BuySellParShares::PURCHASE_ACTIONS + [Engine::Action::PayoffLoan,
                                                                                  Engine::Action::Convert]).freeze

          def actions(entity)
            actions = super.dup
            actions << 'pass' unless actions.empty?
            actions
          end
        end
      end
    end
  end
end
