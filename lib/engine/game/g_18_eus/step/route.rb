# frozen_string_literal: true

require_relative '../../../step/route'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class Route < Engine::Step::Route
          include SkipBny
        end
      end
    end
  end
end
