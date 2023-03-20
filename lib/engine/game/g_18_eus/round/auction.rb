# frozen_string_literal: true

require_relative 'bidbox_auction'

module Engine
  module Game
    module G18EUS
      module Round
        class Auction < Engine::Round::Auction
          include Engine::Game::G18EUS::Round::BidboxAuction

          attr_accessor :bids

          def setup
            @taken_loans = []
            @paid_loans = []
            super
          end

          def after_process(_action)
            return if active_step

            next_entity!
          end

          def next_entity!
            if finished?
              # Need to move entity round once more to be back to the priority deal player
              next_entity_index!

              finish_round
              return
            end

            next_entity_index!
            start_entity
          end

          def start_entity
            @steps.each(&:unpass!)
            @steps.each(&:setup)

            skip_steps
            next_entity! unless active_step
          end

          def finished?
            @game.finished || @entities.all?(&:passed?)
          end
        end
      end
    end
  end
end
