# frozen_string_literal: true

require_relative '../../../round/stock'

module Engine
  module Game
    module G18EUS
      module Round
        class StockCorpAuction < Engine::Round::Stock
          attr_accessor :dummy_corporation

          def setup
            @game.create_auction_corporation
            super
          end
        end
      end
    end
  end
end
