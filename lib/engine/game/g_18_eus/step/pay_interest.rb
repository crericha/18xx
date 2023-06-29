# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18EUS
      module Step
        class PayInterest < Engine::Step::Base
          ACTIONS = %w[pay_interest].freeze

          def actions(entity)
            return [] if entity != @game.bny || entity != current_entity

            ACTIONS
          end

          def auto_actions(entity)
            return super if entity != @game.bny || entity != current_entity

            [Action::PayInterest.new(entity)]
          end

          def process_pay_interest(_action)
            interest = @game.interest_rate
            @game.players.each do |player|
              next unless player.loans.positive?

              @game.take_loan(player) while player.cash < interest * player.loans && @game.can_take_loan?(player)

              player.spend(interest * player.loans, @game.bank, check_cash: false)
              @log << "#{player.name} pays #{@game.format_currency(interest * player.loans)} in interest " \
                      "(#{@game.format_currency(interest)} per share)"
            end
            pass!
          end

          def skip!; end
        end
      end
    end
  end
end
