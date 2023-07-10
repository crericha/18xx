# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'
require_relative 'parrer'
require_relative 'loan_taker'

module Engine
  module Game
    module G18EUS
      module Step
        class BaseBuySellParShares < Engine::Step::BuySellParShares
          include LoanTaker
          include Parrer

          PURCHASE_ACTIONS = (Engine::Step::BuySellParShares::PURCHASE_ACTIONS + [
              Engine::Action::Bid, Engine::Action::PayoffLoan, Engine::Action::Convert
          ]).freeze

          def actions(entity)
            return corporation_actions(entity) if entity.corporation? && entity.owned_by?(current_entity)

            super
          end

          def corporation_actions(entity)
            return [] if bought? || !can_convert?(entity)

            %w[convert pass]
          end

          def can_convert?(corporation)
            corporation.total_shares == 5 && corporation.operated?
          end

          def process_convert(action)
            corporation = action.entity
            raise GameError, "Cannot act for another player's corporation" unless corporation.owned_by?(current_entity)

            @game.grow_corporation(corporation)
            track_action(action, corporation)
          end

          def can_buy_multiple?(_entity, corporation, owner)
            super || (@round.current_actions.any? { |a| a.is_a?(Action::Convert) && a.entity == corporation } &&
              @round.current_actions.count { |a| a.is_a?(Action::BuyShares) && a.bundle.corporation == corporation } < 3)
          end

          def can_buy_any_from_player?(entity)
            @game.corporations.each do |corporation|
              owner = corporation.owner
              next if !can_buy_from_president?(corporation) || owner == entity

              return can_buy_shares?(entity, owner.shares_of(corporation).reject(&:president))
            end

            false
          end

          def can_buy?(entity, bundle)
            corporation = bundle.corporation
            return false if bundle.owner&.player? &&
                            (bundle.presidents_share ||
                             !can_buy_from_president?(corporation) ||
                             corporation.owner != bundle.owner)
            return false if entity.loans.positive? && bundle.corporation == @game.bny

            super
          end

          def can_buy_from_president?(corp)
            !@game.end_set &&
            corp.owner&.player? &&
            corp.owner.percent_of(corp) > 60 &&
            corp.num_market_shares.zero? &&
            corp.num_ipo_shares.zero?
          end

          def modify_purchase_price(bundle)
            return @game.stock_market.find_share_price(bundle.corporation, :right).price if bundle.owner&.player?

            super
          end

          def allow_president_change?(corporation)
            corporation == @game.bny ? false : super
          end

          def can_dump?(_entity, bundle)
            bundle.corporation == @game.bny ? true : super
          end
        end
      end
    end
  end
end
