# frozen_string_literal: true

require_relative '../../../step/base'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class SellTrain < Engine::Step::Base
          include SkipBny

          ACTIONS = %w[scrap_train pass].freeze

          def actions(entity)
            return [] if entity != current_entity ||
                         @sold_train ||
                         @game.train_salesman&.owner != entity ||
                         scrappable_trains(entity).empty?

            ACTIONS
          end

          def description
            'Sell Train'
          end

          def sell_value(train)
            train.price / 2
          end

          def scrappable_trains(entity)
            entity.trains.reject do |t|
              @game.class::EXTRA_TRAINS.include?(t.name) || @game.class::TRAIN_ATTACHMENTS.include?(t.name)
            end
          end

          def scrap_info(train)
            @game.format_currency(sell_value(train)).to_s
          end

          def scrap_header_text
            'Trains to Sell'
          end

          def scrap_button_text(_train)
            'Sell'
          end

          def process_scrap_train(action)
            raise GameError, 'Can only sell trains owned by the corporation' if action.entity != action.train.owner

            train = action.train

            @log << "#{train.owner.name} uses #{@game.train_salesman.name} to sell a #{train.name}" \
                    " train for #{@game.format_currency(sell_value(train))}"
            @game.bank.spend(sell_value(train), train.owner)
            @game.remove_train(train)
            @sold_train = true
          end

          def log_skip(_entity); end

          def setup
            super
            @sold_train = false
          end
        end
      end
    end
  end
end
