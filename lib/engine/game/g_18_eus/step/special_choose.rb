# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialChoose < Engine::Step::SpecialChoose
          def actions(entity)
            return [] if entity.owner != current_entity || !current_entity.corporation?

            actions = super
            return [] if actions && entity == @game.responsible_president && !@game.can_payoff_loan?(entity.owner.owner)

            actions
          end

          def choices_ability(entity)
            return bank_lobbyist_choices if entity == @game.bank_lobbyist

            super
          end

          def bank_lobbyist_choices
            choices = {}
            [@game.loans_taken, 4].min.times.with_index(1) { |_, i| choices[i.to_s] = "Add #{i} loan#{i == 1 ? '' : 's'}" }
            [@game.loans_available, 4].min.times.with_index(1) do |_, i|
              choices[(-i).to_s] = "Remove #{i} loan#{i == 1 ? '' : 's'}"
            end
            choices
          end

          def process_choose_ability(action)
            entity = action.entity

            case entity
            when @game.late_bloomer
              process_late_bloomer_choose_ability(action)
            when @game.responsible_president
              player = entity.owner.owner
              raise GameError, "#{player.name} cannot payoff a loan" if !@game.loading && !@game.can_payoff_loan?(player)

              @game.payoff_loan(entity.owner.owner)
              abilities(entity).use!
            when @game.bank_lobbyist
              raise "Invalid choice for #{entity.name}" if !@game.loading && !bank_lobbyist_choices.include?(action.choice)

              num_loans = action.choice.to_i
              @game.loans_taken -= num_loans
              @log << "#{entity.name} #{num_loans.positive? ? 'adds' : 'removes'} #{num_loans.abs}" \
                      " loan#{num_loans.abs == 1 ? '' : 's'} #{num_loans.positive? ? 'to' : 'from'} #{@game.bny.name}"
            when @game.reappraisal
              increase_share_price(entity.owner)
            when @game.bank_reappraisal
              increase_share_price(@game.bny)
            end

            entity.close! unless entity == @game.responsible_president
          end

          def process_late_bloomer_choose_ability(action)
            entity = action.entity
            if (private = @game.late_bloomer_companies.find { |c| c.name == action.choice })
              @game.companies << private
              private.owner = entity.owner
              entity.owner.companies << private
            else
              @game.bank.spend(@game.class::LATE_BLOOMER_CASH, entity.owner)
            end

            @log << "#{entity.owner.name} swaps #{entity.name} for #{action.choice}"
          end

          def increase_share_price(entity)
            old_price = entity.share_price
            @game.stock_market.move_right(entity)
            @game.log_share_price(entity, old_price, 1)
          end
        end
      end
    end
  end
end
