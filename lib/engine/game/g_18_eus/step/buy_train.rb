# frozen_string_literal: true

require_relative '../../../step/buy_train'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          include SkipBny

          def actions(entity)
            if entity == current_entity.owner
              return emr_buy?(@round.current_operator) ? %w[sell_shares] : []
            end

            return [] unless entity == current_entity

            actions = []
            if must_buy_train?(entity)
              actions << 'buy_train'
              actions << 'sell_shares' if can_issue?(entity)
            elsif can_buy_train?(entity)
              actions = %w[buy_train pass]
            end

            actions
          end

          def can_issue?(entity)
            return false if @emr_issued || @emr_sold_shares
            return false unless entity.corporation?
            return false unless emr_buy?(entity)

            !@game.emergency_issuable_bundles(entity).empty?
          end

          def emr_buy?(corp)
            must_buy_train?(corp) && corp.cash < @depot.min_depot_price
          end

          def process_sell_shares(action)
            entity = action.entity
            if entity.player?
              @emr_sold_shares = true
              return super
            end

            @emr_issued = true
            @game.sell_shares_and_change_price(action.bundle, movement: :left_share)
          end

          def setup
            @emr_issued = false
            @emr_sold_shares = false
            super
          end
        end
      end
    end
  end
end