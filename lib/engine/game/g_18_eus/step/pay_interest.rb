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
            @game.players.each do |player|
              next unless player.loans.positive?

              while player.cash < @game.interest_owed_for_loans(player.loans) && @game.can_take_loan?(player)
                @game.take_loan(player)
              end

              interest_owed = @game.interest_owed_for_loans(player.loans)
              player.spend(interest_owed, @game.bank, check_cash: false)
              @log << "#{player.name} pays #{@game.format_currency(interest_owed)} in interest " \
                      "on #{player.loans} loan#{player.loans > 1 ? 's' : ''}"
            end
            pass!
          end

          def skip!; end
        end
      end
    end
  end
end
