# frozen_string_literal: true

require_relative '../../../step/passable_auction'

module Engine
  module Game
    module G18EUS
      module Step
        module CityAuctioneer
          include Engine::Step::PassableAuction

          def actions(entity)
            return super unless entity == current_entity
            return super if @auction_state && choice_available?(entity)
            return auction_actions(entity) if @auction_state

            actions = []
            actions.concat(super)
            if can_auction_city?(entity)
              actions << 'choose'
              actions.delete('par')
            end
            actions
          end

          def auction_actions(entity)
            actions = case auction_state
                      when :initial_bid
                        %w[bid]
                      when :bid
                        %w[bid pass]
                      when :par
                        %w[par]
                      when :buy_shares
                        %w[buy_shares pass]
                      end
            actions << 'take_loan' if can_take_loan?(entity)
            actions
          end

          def can_auction_city?(entity)
            entity == current_entity && entity.player? && !bought? && auction_start? && entity.cash >= (min_par_price * 2)
          end

          def active_entities
            return [@winner] if @winner
            return super unless @auctioning

            [@active_bidders[(@active_bidders.index(highest_bid(@auctioning).entity) + 1) % @active_bidders.size]]
          end

          def bid_entity
            @auctioning || auction_corp
          end

          def auction_corp
            @game.auction_corporation
          end

          def auction_hex
            auction_corp.tokens.first.hex
          end

          def auction_hex_str
            hex = auction_hex
            "#{hex.id} (#{hex.location_name})"
          end

          def auction_state
            @auction_state || :start
          end

          def auction_start?
            auction_state == :start
          end

          def can_bid?(_entity)
            true
          end

          def bid_description
            "Auctioning #{auction_hex_str}"
          end

          def min_bid(entity)
            if auction_state == :bid
              highest_bid(entity).price + min_increment
            else
              0
            end
          end

          def max_bid(player, _entity)
            player.cash - (min_par_price * 2)
          end

          def min_par_price
            50
          end

          def choice_available?(entity)
            super || can_auction_city?(entity)
          end

          def choice_name
            return nil if auction_start?

            super
          end

          def choices
            return ['Auction City Location'] if can_auction_city?(current_entity)

            super
          end

          def process_choose(action)
            return super unless can_auction_city?(action.entity)
            raise GameError, "#{action.entity.name} cannot auction city location" unless can_auction_city?(action.entity)

            @auction_state = :initial_bid
            @round.pending_tokens << {
              entity: auction_corp,
              hexes: @game.home_token_locations(auction_corp),
              token: auction_corp.tokens.first,
            }
            @round.pass_order.delete(action.entity)
            @log << "#{action.entity.name} starts auction for city location"
          end

          def process_bid(action)
            auction_state == :initial_bid ? selection_bid(action) : add_bid(action)
            @auction_state = :bid
            track_action(action, bid_target(action))
          end

          def process_par(action)
            @parred_corporation = action.corporation
            auction_corp.tokens.first.swap!(@parred_corporation.tokens.first)

            super
            @auction_state = :buy_shares
            reset_auction unless can_buy_additional_shares?
          end

          def process_buy_shares(action)
            super
            return unless @auction_state == :buy_shares

            reset_auction unless can_buy_additional_shares?
          end

          def can_buy_additional_shares?
            can_buy_shares?(@winner, @parred_corporation.shares)
          end

          def add_bid(action)
            @log << "#{action.entity.name} bids #{@game.format_currency(action.price)} on #{auction_hex_str}"
            super
          end

          def win_bid(winner, _company)
            @winner = winner.entity
            @auction_state = :par

            price = winner.price

            @log << "#{@winner.name} wins bid on #{auction_hex_str} for #{@game.format_currency(price)}"
            @winner.spend(price, @game.bank) if price.positive?
          end

          def pass_description
            auction_state == :bid ? 'Pass (Bid)' : super
          end

          def pass_auction(entity)
            @log << "#{entity.name} passes on #{auction_hex_str}"
            remove_from_auction(entity)
          end

          def pass!
            if auction_state == :bid
              pass_auction(current_entity)
              resolve_bids
              return
            end

            reset_auction if @auction_state
            super
          end

          def reset_auction
            @auction_state = nil
            @winner = nil
            @parred_corporation = nil
          end

          def setup
            setup_auction
            super
            @auction_state = nil
            @winner = nil
            @parred_corporation = nil
          end
        end
      end
    end
  end
end
