# frozen_string_literal: true

module Engine
  module Game
    module G18EUS
      module SkipBny
        def actions(entity)
          return [] if @game.bny == entity

          super
        end

        def log_skip(entity)
          super unless @game.bny == entity
        end
      end
    end
  end
end
