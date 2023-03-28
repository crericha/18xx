# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module Step
        class QuickStarterPurchaseTrain < Engine::Step::Base
          ACTIONS = %w[purchase_train].freeze

          def description
            "#{b9.name} Train Purchase"
          end

          def active?
            !b9&.closed?
          end

          def actions(entity)
            return [] if b9 != entity || !current_entity&.corporation? || current_entity != entity.owner
            return [] unless can_purchase?(current_entity)

            ACTIONS
          end

          def b9
            @b9 ||= @game.company_by_id('B9')
          end

          def current_train
            @game.depot.depot_trains.first
          end

          def current_train_price
            current_train.min_price(ability: @game.abilities(current_entity, :train_discount))
          end

          def can_purchase?(corp)
            current_train_price <= corp.cash and room?(corp)
          end

          def room?(corp)
            corp.trains.size < @game.train_limit(corp)
          end

          def log_skip(_entity); end

          def blocking?
            false
          end

          def process_purchase_train(action)
            company = action.entity
            train = current_train
            price = current_train_price

            @log << "#{company.owner.name} (#{company.name}) purchases #{train.name} train" \
                    " for #{@game.format_currency(price)}"

            company.close!
            @log << "#{company.name} closes"

            source = train.owner
            @game.buy_train(@round.current_operator, train, price)
            @game.phase.buying_train!(@round.current_operator, train, source)
          end
        end
      end
    end
  end
end
