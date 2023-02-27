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
        end
      end
    end
  end
end
