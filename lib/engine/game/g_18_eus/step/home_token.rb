# frozen_string_literal: true

require_relative '../../../step/home_token'

module Engine
  module Game
    module G18EUS
      module Step
        class HomeToken < Engine::Step::HomeToken
          def process_place_token(action)
            corporation = token.corporation
            super
            @game.after_par(corporation)
          end
        end
      end
    end
  end
end
