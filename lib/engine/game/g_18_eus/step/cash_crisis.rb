# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../../../step/emergency_money'

module Engine
  module Game
    module G18EUS
      module Step
        class CashCrisis < Engine::Step::Base
          include Engine::Step::EmergencyMoney

          def actions(entity)
            return [] if entity != current_entity

            ['sell_shares']
          end

          def description
            'Cash Crisis'
          end

          def cash_crisis?
            true
          end

          def active?
            !active_entities.empty?
          end

          def current_entity
            @round.cash_crisis_entity
          end

          def active_entities
            entity = @game.players.find { |p| p.cash.negative? }
            if entity && entity != @round.cash_crisis_entity
              @game.log << "#{entity.name} enters Cash Crisis and owes"\
                           " the bank #{@game.format_currency(needed_cash(entity))}"
            end
            @round.cash_crisis_entity = entity

            [entity].compact
          end

          def needed_cash(entity)
            -entity.cash
          end

          def available_cash(_player)
            0
          end

          def swap_sell(_player, _corporation, _bundle, _pool_share); end

          def process_take_loan(action)
            @game.take_loan(action.entity)
          end

          def round_state
            { 'cash_crisis_entity' => nil, **super }
          end
        end
      end
    end
  end
end
