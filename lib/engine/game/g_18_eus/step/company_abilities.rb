# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Step
        class CompanyAbilities < Engine::Step::Base
          ACTIONS = %w[pass].freeze

          def description
            'Use Company Abilities'
          end

          def pass_description
            'Pass (Companies)'
          end

          def active?
            super && block_for_companies?(current_entity)
          end

          def actions(entity)
            return [] if current_entity != entity

            ACTIONS
          end

          def blocking_companies(entity)
            blocking = []
            blocking << @game.responsible_president if responsible_president_blocks?(entity)
            blocking << @game.reappraisal if @game.reappraisal&.owner == entity

            blocking
          end

          def responsible_president_blocks?(entity)
            company = @game.responsible_president
            company&.owner == entity &&
              @game.can_payoff_loan?(entity.owner) &&
              @game.abilities(company, :choose_ability)
          end

          def block_for_companies?(entity)
            return false unless entity&.corporation?

            !blocking_companies(entity).empty?
          end

          def log_skip(_entity); end
        end
      end
    end
  end
end
