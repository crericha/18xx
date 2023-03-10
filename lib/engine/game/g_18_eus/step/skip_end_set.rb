# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module SkipEndSet
        def actions(entity)
          return [] if skip?

          super
        end

        def log_skip(entity)
          return if skip?

          super
        end

        def skip?
          !@round.is_a?(G18EUS::Round::FinalBuild) && @game.end_set
        end
      end
    end
  end
end
