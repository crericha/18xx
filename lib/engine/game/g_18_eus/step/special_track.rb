# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative 'remove_subsidies'

module Engine
  module Game
    module G18EUS
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          include RemoveSubsidies
        end
      end
    end
  end
end
