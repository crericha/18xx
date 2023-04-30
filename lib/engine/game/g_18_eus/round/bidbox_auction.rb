# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Round
        module BidboxAuction
          attr_accessor :bids

          def setup
            @game.next_auctions!
            @stored_winning_bids = Hash.new { |h, k| h[k] = [] }
            super
          end

          def player_enabled_program(entity)
            # Update winning bids to exclude being outbid prior to enabling program.
            update_stored_winning_bids(entity)
          end

          def stored_winning_bids(entity)
            @stored_winning_bids[entity]
          end

          def update_stored_winning_bids(entity)
            winning_bids = []
            check_winning = lambda { |bid_target|
              return unless (bid = highest_bid(bid_target))
              return unless bid.entity == entity

              winning_bids << bid_target
            }

            @game.bidbox_privates.each(&check_winning)

            @stored_winning_bids[entity] = winning_bids
          end

          def finish_round
            @game.bidbox_privates.each do |company|
              if (bid = highest_bid(company))
                buy_company(bid)
              else
                discard_company(company)
              end
            end
            super
          end

          def buy_company(bid)
            player = bid.entity
            company = bid.company
            price = bid.price

            company.value = 50 + [bid.price, 100].min if company == presidential_financing

            company.owner = player
            player.companies << company
            player.spend(price, @game.bank) if price.positive?
            @log << "#{player.name} wins the bid #{company.name} for #{@game.format_currency(price)}"
          end

          def discard_company(company)
            @log << "#{company.name} has no bids and is discarded"
            company.owner = nil
            company.close!
          end

          def highest_bid(company)
            @bids[company]&.max_by(&:price)
          end

          def presidential_financing
            @presidential_financing ||= @game.company_by_id('B1')
          end
        end
      end
    end
  end
end
