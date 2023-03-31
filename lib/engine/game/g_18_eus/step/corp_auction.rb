# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Step
        module CorpAuction
          include Engine::Step::PassableAuction
          include Parrer
          PURCHASE_ACTIONS = (Engine::Step::BuySellParShares::PURCHASE_ACTIONS + [Engine::Action::Bid]).freeze

          def round_state
            super.merge(
              {
                bids: Hash.new { |h, k| h[k] = [] },
              }
            )
          end

          def setup
            setup_auction
            super
            @bid_actions = 0
            @bids = @round.bids
          end

          def actions(entity)
            actions = super.dup
            return actions unless entity == current_entity
            return actions if actions.include?('choose') # Not sure if this is the best way to do this
            return ['par'] if @auction_winner
            return ['bid', 'pass'] if auctioning?
            actions << 'bid' if !auctioning? && can_start_auction?(entity)
            actions.uniq
          end

          def can_start_auction?(entity)
            @game.corporations.any? { |c| !c.ipoed } && entity.cash >= (2 * @game.stock_market.par_prices.map(&:price).min)
          end

          def can_be_auctioned?(player, corporation)
            !corporation.ipoed && can_open_company?(player)
          end

          def min_par_amount
            2 * @game.stock_market.par_prices.map(&:price).min
          end

          def can_open_company?(player)
            player.cash >= min_par_amount
          end

          def store_bids!
            @round.bids = @bids
          end

          def process_bid(action)
            action.entity.unpass!

            if auctioning
              @log << "#{action.entity.name} bids #{@game.format_currency(action.price)}"
              add_bid(action)
            else
              @log << "#{action.entity.name} bids #{@game.format_currency(action.price)} on a new company"
              selection_bid(action)
              @log << "#{action.entity.name} must pick a location for the new company"
              @round.pending_tokens << {
                entity: @game.auction_corporation,
                hexes: @game.home_token_locations(@game.auction_corporation),
                token: @game.auction_corporation.tokens.first,
              }
              next_entity! if auctioning # TODO - if auctioning needed?
            end
            store_bids!
          end

          def win_bid(action, company)
            winner = action.entity
            price = action.price
            @log << "#{winner.name} wins the auction for the new company with a bid of #{@game.format_currency(price)}"
            @log << "#{winner.name} must pick a company and a par value"
            winner.spend(price, @game.bank) if price.positive?
            @auction_winner = winner
          end

          def next_entity!
            @round.next_entity_index!
            entity = entities[entity_index]
            next_entity! if entity&.passed?
          end


          def ipo_type(corporation)
            corporation == @game.auction_corporation ? :bid : :par
          end

          def min_bid(company)
            #return unless company

            high_bid = highest_bid(company)
            (high_bid ? high_bid.price + min_increment : 0)
          end

          def max_bid(player, _company)
            player.cash - min_par_amount
          end

          def max_bid
            9999
          end

          def min_increment
            5
          end

          def min_player_bid
            0
          end

          def max_player_bid(_entity)
            9999
          end

          def committed_cash
            0
          end

          def player_can_bid
            true
          end

          def visible_corporations
            @game.sorted_corporations.reject(&:closed?).reject{|c| c == @game.auction_corporation}
          end

          def auctioning_corporation
            auctioning? ? @game.auction_corporation : nil
          end

          def bid_description
            !auctioning? ? 'Start auction on new company' : "Bid on new company with home token on #{@game.auction_corporation.tokens.first.hex.id}"
          end

          def pass_description
            auctioning? ? 'Pass on new company' : 'Pass'
          end
    
          def player_bid_corp
            @game.auction_corporation
          end

          def can_buy?(entity, bundle)
            bundle.corporation == @game.auction_corporation || auctioning? ? false : super
          end

          def auctioning?
            !bids[@game.auction_corporation].empty?
          end

          def hide_corporations?
            auctioning?
          end

          def process_pass(action)
            return super if !auctioning?

            @log << "#{action.entity.name} passes"
            remove_from_auction(action.entity)
          end
      
          def active_entities
            if @auction_winner
              return [@auction_winner]
            end

            if @auctioning
              winning_bid = highest_bid(@auctioning)
              return [@active_bidders[(@active_bidders.index(winning_bid.entity) + 1) % @active_bidders.size]] if winning_bid
            end

            super
          end

          def process_par(action)
            entity = action.entity
            corporation = action.corporation
            share_price = action.share_price

            city = @game.auction_corporation.tokens[0].city
            @game.auction_corporation.tokens[0].remove!
            city.place_token(corporation, corporation.find_token_by_type, check_tokenable: false)

            @bids.clear
            @active_bidders.clear
            @auctioning = nil
            @auction_winner = nil

            super

          end

          def process_choose(action)
            super
          end
        end
      end
    end
  end
end
