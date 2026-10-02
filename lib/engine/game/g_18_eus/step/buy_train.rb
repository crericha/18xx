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
            return [] if @game.bny == entity

            if entity == current_entity.owner
              actions = []
              if emr_buy?(@round.current_operator)
                actions << 'sell_shares'
                actions << 'take_loan' if @game.can_take_loan?(entity)
              end
              return actions
            end

            return [] unless entity == current_entity

            actions = []
            if must_buy_train?(entity)
              actions << 'buy_train'
              actions << 'sell_shares' if can_issue?(entity)
            else
              actions << 'buy_train' if can_buy_train?(entity)
              actions << 'choose' if can_ignore_little_engine?(entity)
              actions << 'pass' unless actions.empty?
            end

            actions
          end

          def can_ignore_little_engine?(entity)
            return false unless entity.corporation?
            return false unless entity.trains.include?(@game.little_engine)
            return false if @game.little_engine_ignored?(entity)

            entity.cash < @depot.min_depot_price && entity.trains.none? do |t|
              t != @game.little_engine && @game.counts_for_train_ownership?(t, entity)
            end
          end

          def choice_name
            "Don't count the Little Engine toward train ownership"
          end

          def choices
            { 'ignore_little_engine' => 'Emergency buy a train' }
          end

          def choice_explanation
            ["#{current_entity.name} must then buy a train from the Next Available Train stack,"\
             ' using emergency fund-raising if needed. This may bankrupt the president.']
          end

          def process_choose(action)
            entity = action.entity
            raise GameError, "#{entity.name} cannot ignore the Little Engine" unless can_ignore_little_engine?(entity)

            @round.little_engine_ignored = entity
            @log << "#{entity.owner.name} chooses not to count the Little Engine toward"\
                    " #{entity.name}'s train ownership, so #{entity.name} must buy a train"
          end

          def round_state
            super.merge(little_engine_ignored: nil)
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

          def process_take_loan(action)
            @game.take_loan(action.entity)
          end

          def setup
            @emr_issued = false
            @emr_sold_shares = false
            @round.little_engine_ignored = nil
            super
          end
        end
      end
    end
  end
end
