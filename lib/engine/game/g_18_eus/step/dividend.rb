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
          def actions(entity)
            return super unless entity == @game.bny

            ACTIONS
          end

          def auto_actions(entity)
            return super unless entity == @game.bny

            [Action::Dividend.new(entity, kind: 'payout')]
          end

          def share_price_change(entity, revenue = 0)
            price = entity.share_price.price
            return { share_direction: :left, share_times: 2 } if revenue.zero?

            jumps = [2, (revenue.to_f / price).floor].min
            return { share_direction: :right, share_times: jumps * 2 } if jumps.positive?

            {}
          end

          def movement_str(times, dir)
            "#{times / 2} #{dir}"
          end

          def corporation_dividends(entity, per_share)
            entity == @game.bny ? 0 : super
          end

          def process_dividend(action)
            return super unless action.entity == @game.bny

            interest = (@game.bny.share_price.price / 10).round    # TODO: This is wrong - fix after changing stock market
            movement, multiplier = @game.current_loan_values

            @game.players.each do |player|
              next unless player.loans.positive?

              player.spend(interest * player.loans, @game.bank)
              @log << "#{player.name} pays #{@game.format_currency(interest * player.loans)} in interest " \
                      "(#{@game.format_currency(interest)} per share)"
            end

            payout = send(:payout, action.entity, interest * multiplier * 10)
            payout_shares(action.entity, interest * multiplier * 10) if payout[:per_share].positive?

            spaces = stock_movement_to_spaces(movement)
            if spaces.positive?
              spaces.times { @game.stock_market.move_right(@game.bny) }
              @log << "BNY moves #{spaces} diagonal space(s) to the right to " \
                      "#{@game.format_currency(@game.bny.share_price.price)}"
            end

            if @game.bny.num_treasury_shares < 10
              @game.stock_market.move_right(@game.bny)
              @log << 'BNY moves 1 additional diagonal space to the right to ' \
                      "#{@game.format_currency(@game.bny.share_price.price)} because it has shareholders"
            end
            pass!
          end

          def stock_movement_to_spaces(movement)
            case movement
            when :none then 0
            when :diagonal then 1
            when :straight then 2
            when :diagonal_then_straight then 3
            end
          end
        end
      end
    end
  end
end
