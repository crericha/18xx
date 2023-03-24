# frozen_string_literal: true

require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Round
        class Auction < Engine::Round::Stock
          include BidboxAuction
          def name
            'Initial Auction Round'
          end

          def self.short_name
            'IA'
          end
        end
      end
    end
  end
end
