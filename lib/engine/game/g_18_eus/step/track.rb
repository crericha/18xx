# frozen_string_literal: true

require_relative '../../../step/track'
require_relative 'tracker'

module Engine
  module Game
    module G18EUS
      module Step
        class Track < Engine::Step::Track
          include Tracker
        end
      end
    end
  end
end
