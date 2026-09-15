# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Step
        module LoanTaker
          def round_state
            super.merge(
              {
                taken_loans: [],
                paid_loans: [],
              }
            )
          end

          def actions(entity)
            actions = super.dup
            return actions unless entity == current_entity

            actions << 'take_loan' if can_take_loan?(entity)
            actions << 'payoff_loan' if can_payoff_loan?(entity)
            actions << 'pass' unless actions.empty?
            actions.concat(super).uniq
          end

          def can_take_loan?(entity)
            entity.player? &&
              @game.can_take_loan?(entity) &&
              (!bought? || can_buy_multiple_with_loans?(entity))
          end

          def can_buy_multiple_with_loans?(entity)
            @game.corporations.any? do |corp|
              next unless corp.ipoed

              can_buy_multiple?(entity, corp, corp) &&
                (@game.buying_power(entity) - committed_cash(entity)) >= corp.share_price.price
            end
          end

          def process_take_loan(action)
            @game.take_loan(action.entity)
            track_action(action, @game.bny)
            @round.taken_loans |= [action.entity]
          end

          def can_payoff_loan?(entity)
            !bought? &&
              entity.player? &&
              !@round.taken_loans.include?(entity) &&
              @game.can_payoff_loan?(entity, available_cash(entity))
          end

          def process_payoff_loan(action)
            @game.payoff_loan(action.entity)
            track_action(action, @game.bny)
            @round.paid_loans |= [action.entity]
            pass!
          end

          def activate_program_payoff_loans(entity, program)
            reason = if !entity.loans.positive?
                       'No loans to pay off'
                     elsif @round.taken_loans.include?(entity)
                       'Took a loan this stock round'
                     elsif !actions(entity).include?('payoff_loan')
                       'Cannot afford to pay off a loan'
                     else
                       should_stop_applying_program(entity, program, nil)
                     end
            return [Action::ProgramDisable.new(entity, reason: reason)] if reason

            [Action::PayoffLoan.new(entity, loan: nil)]
          end
        end
      end
    end
  end
end
