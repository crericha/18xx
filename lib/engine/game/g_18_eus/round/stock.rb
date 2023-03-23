# frozen_string_literal: true

require_relative '../../../round/stock'
require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Round
        class Stock < Engine::Round::Stock
          include BidboxAuction

          def can_buy_company?(_player, _company)
            false # Only companies are privates
          end
        end
      end
    end
  end
end
