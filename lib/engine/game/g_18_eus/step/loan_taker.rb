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
            actions.concat(super).uniq
          end

          def can_take_loan?(entity)
            !bought? && entity.player? && !@round.paid_loans.include?(entity) && @game.can_take_loan?(entity)
          end

          def process_take_loan(action)
            @game.take_loan(action.entity)
            track_action(action, @game.bny)
            @round.taken_loans |= [action.entity]
          end

          def can_payoff_loan?(entity)
            !bought? && entity.player? && !@round.taken_loans.include?(entity) && @game.can_payoff_loan?(entity)
          end

          def process_payoff_loan(action)
            @game.payoff_loan(action.entity)
            track_action(action, @game.bny)
            @round.paid_loans |= [action.entity]
            pass!
          end

          def game_buttons(entity)
            buttons = super
            if can_take_loan?(entity)
              action = Engine::Action::TakeLoan.new(entity, loan: nil)
              buttons << { action: action, description: "Take Loan (#{@game.format_currency(@game.loan_amount)})" }
            end
            if can_payoff_loan?(entity)
              action = Engine::Action::PayoffLoan.new(entity, loan: nil)
              buttons << { action: action, description: "Payoff Loan (#{@game.format_currency(@game.loan_amount)})" }
            end
            buttons
          end
        end
      end
    end
  end
end
