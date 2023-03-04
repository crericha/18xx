# frozen_string_literal: true

require_relative '../../../step/dividend'
require_relative '../../../step/half_pay'

module Engine
  module Game
    module G18EUS
      module Step
        class Dividend < Engine::Step::Dividend
          DIVIDEND_TYPES = %i[payout half withhold].freeze
          include Engine::Step::HalfPay

          ACTIONS = ['dividend'].freeze
          def actions(_entity)
            ACTIONS
          end

          def auto_actions(entity)
            return super unless entity == @game.bny

            [Action::Dividend.new(entity, kind: 'payout')]
          end

          STOCK_MOVEMENT_SPACES = { none: 0, diagonal: 1, straight: 2, diagonal_then_straight: 3 }.freeze

          def share_price_change(entity, revenue = 0)
            if entity == @game.bny
              spaces = STOCK_MOVEMENT_SPACES[@game.current_loan_movement]
              spaces += 1 if @game.bny.num_treasury_shares < 10
              return spaces.positive? ? { share_direction: :up, share_times: spaces } : {}
            end

            price = entity.share_price.price
            return { share_direction: :left, share_times: 1 } if revenue.zero?

            jumps = [2, (revenue.to_f / price).floor].min
            return { share_direction: :right, share_times: jumps } if jumps.positive?

            {}
          end

          def corporation_dividends(entity, per_share)
            entity == @game.bny ? 0 : super
          end

          def process_dividend(action)
            pay_interest if action.entity == @game.bny
            super
          end

          def pay_interest
            interest = @game.bny.share_price.info.to_i

            @game.players.each do |player|
              next unless player.loans.positive?

              player.spend(interest * player.loans, @game.bank)
              @log << "#{player.name} pays #{@game.format_currency(interest * player.loans)} in interest " \
                      "(#{@game.format_currency(interest)} per share)"
            end
          end
        end
      end
    end
  end
end
