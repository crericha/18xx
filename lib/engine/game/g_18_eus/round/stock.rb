# frozen_string_literal: true

require_relative '../../../round/stock'
require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Round
        class Stock < Engine::Round::Stock
          include BidboxAuction
        end
      end
    end
  end
end
