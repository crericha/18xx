# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative 'tracker'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          include Tracker
        end
      end
    end
  end
end
