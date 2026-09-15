# frozen_string_literal: true

require 'view/game/auto_action/base'

module View
  module Game
    module AutoAction
      class PayoffLoans < Base
        def name
          "Auto Payoff Loans #{' (Enabled)' if @settings}"
        end

        def description
          "Pay off a loan on each of your turns during #{@game.stock_round_name} while you have loans and can "\
            'afford to. Paying off a loan ends your turn. Disables when you have no loans or cannot afford one.'
        end

        def render
          children = [h(:h3, name), h(:p, description)]

          subchildren = [render_button(@settings ? 'Update' : 'Enable') { enable }]
          subchildren << render_disable if @settings
          children << h(:div, subchildren)

          children
        end

        def enable
          process_action(Engine::Action::ProgramPayoffLoans.new(@sender))
        end
      end
    end
  end
end
