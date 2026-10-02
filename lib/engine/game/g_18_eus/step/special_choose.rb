# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialChoose < Engine::Step::SpecialChoose
          def actions(entity)
            return [] if entity.owner != current_entity || !current_entity.corporation?
            return [] if entity == @game.bank_lobbyist && bank_lobbyist_choices.empty?
            if entity == @game.responsible_president &&
                (!entity.owner&.corporation? || !@game.can_payoff_loan?(entity.owner.owner))
              return []
            end

            super
          end

          def choices_ability(entity)
            return bank_lobbyist_choices if entity == @game.bank_lobbyist

            super
          end

          def choices_ability_companies(entity)
            return unless entity == @game.late_bloomer

            @game.late_bloomer_choice_companies.to_h { |company| [company.sym, company] }
          end

          def bank_lobbyist_choices
            return {} if @game.bank_lobbyist.owner.owner.loans.positive?

            num_loans = bank_lobbyist_num_loans
            return {} if num_loans.zero?

            { 'remove_loans' => "Remove #{num_loans} loan#{num_loans == 1 ? '' : 's'}" }
          end

          def bank_lobbyist_num_loans
            [@game.remaining_loans, 4].min
          end

          def process_choose_ability(action)
            entity = action.entity
            return process_bank_lobbyist_choose_ability(action) if entity == @game.bank_lobbyist

            case entity
            when @game.late_bloomer
              process_late_bloomer_choose_ability(action)
            when @game.responsible_president
              player = entity.owner.owner
              raise GameError, "#{player.name} cannot payoff a loan" if !@game.loading && !@game.can_payoff_loan?(player)

              @game.payoff_loan(entity.owner.owner)
              abilities(entity).use!
            when @game.reappraisal
              @log << "#{@game.reappraisal.name} used to increase #{current_entity.name} share price"
              increase_share_price(entity.owner)
            when @game.bank_reappraisal
              @log << "#{@game.bank_reappraisal.name} used to increase #{@game.bny.name} share price"
              increase_share_price(@game.bny)
            end

            entity.close! unless entity == @game.responsible_president
          end

          def process_bank_lobbyist_choose_ability(action)
            entity = action.entity
            if !@game.loading && !bank_lobbyist_choices.include?(action.choice)
              raise GameError, "Invalid choice for #{entity.name}"
            end

            num_loans = bank_lobbyist_num_loans
            @game.loans_taken += num_loans
            @log << "#{entity.name} removes #{num_loans} loan#{num_loans == 1 ? '' : 's'} from #{@game.bny.name}"
            entity.close!
          end

          def process_late_bloomer_choose_ability(action)
            entity = action.entity
            corporation = entity.owner
            choice = @game.late_bloomer_choice_companies.find { |company| company.sym == action.choice }
            raise GameError, "Invalid choice for #{entity.name}" unless choice

            @log << "#{corporation.name} chooses #{choice.name} for #{entity.name}"

            case choice.sym
            when 'LB-CASH'
              @game.bank.spend(@game.class::LATE_BLOOMER_CASH, corporation)
            when 'LB-2P'
              @game.acquire_special_train(corporation, @game.class::TRAIN_2P)
            when 'LB-LOANS'
              remove_late_bloomer_loans(entity)
            else
              @game.add_company_to_game(choice)

              choice.owner = corporation
              corporation.companies << choice
              @game.company_bought(choice, corporation)
            end
          end

          def remove_late_bloomer_loans(entity)
            num_loans = [2, @game.remaining_loans].min
            @game.loans_taken += num_loans
            @log << "#{entity.name} removes #{num_loans} loan#{num_loans == 1 ? '' : 's'} from #{@game.bny.name}"

            old_price = @game.bny.share_price
            @game.stock_market.move_up(@game.bny)
            @game.log_share_price(@game.bny, old_price, 1)
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
