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

          def auto_actions(entity)
            return super unless entity == @game.bny

            [Action::Dividend.new(entity, kind: 'payout')]
          end

          def dividend_options(entity)
            mandatory_payout = entity.trains.include?(@game.little_engine) ? @game.little_engine_revenue : 0
            mandatory_per_share = payout_per_share(entity, mandatory_payout)

            revenue = @game.routes_revenue(routes)
            dividend_types.to_h do |type|
              payout = send(type, entity, revenue - mandatory_payout)
              payout[:per_share] += mandatory_per_share if mandatory_payout
              payout[:divs_to_corporation] = corporation_dividends(entity, payout[:per_share])
              [type, payout.merge(share_price_change(entity, revenue - payout[:corporation]))]
            end
          end

          def share_price_change(entity, revenue = 0)
            if entity == @game.bny
              spaces = @game.bny_stock_movement
              return spaces.positive? ? { share_direction: :up, share_times: spaces } : {}
            end

            price = entity.share_price.price
            return { share_direction: :left, share_times: 1 } if revenue.zero?

            jumps = [max_jumps(entity), (revenue.to_f / price).floor].min
            return { share_direction: :right, share_times: jumps } if jumps.positive?

            {}
          end

          def change_share_price(entity, payout)
            return unless payout[:share_direction]

            super
            @game.interest_rate_changed if entity == @game.bny
          end

          def max_jumps(entity)
            entity.companies.include?(@game.triple_hopper) ? 3 : 2
          end

          def corporation_dividends(entity, per_share)
            entity == @game.bny ? 0 : super
          end

          def payout_shares(entity, revenue)
            super
            return if entity != @game.bny || !bank_bond&.owner

            payout = (revenue / 10.to_f).floor
            @game.bank.spend(payout, bank_bond.owner)
            @log << "#{bank_bond.owner.name} receives #{@game.format_currency(payout)} from #{bank_bond.name}"
          end

          def bank_bond
            @bank_bond ||= @game.company_by_id('A6')
          end

          def log_run_payout(entity, kind, revenue, action, payout)
            return if @game.bny == entity

            super
          end
        end
      end
    end
  end
end
