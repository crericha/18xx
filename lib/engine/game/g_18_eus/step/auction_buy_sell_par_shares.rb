# frozen_string_literal: true

require_relative 'base_buy_sell_par_shares'
require_relative 'city_auctioneer'

module Engine
  module Game
    module G18EUS
      module Step
        class AuctionBuySellParShares < BaseBuySellParShares
          include CityAuctioneer
        end
      end
    end
  end
end
