# frozen_string_literal: true

require_relative '../../../round/stock'
require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Round
        class Stock < Engine::Round::Stock
          include Engine::Game::G18EUS::Round::BidboxAuction
          attr_accessor :bids, :taken_loans, :paid_loans

          def setup
            @taken_loans = []
            @paid_loans = []
            super
          end
        end
      end
    end
  end
end
