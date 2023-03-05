# frozen_string_literal: true

require_relative '../../../step/buy_company'

module Engine
  module Game
    module G18EUS
      module SkipBny
        def actions(entity)
          return [] if @game.bny == entity

          super
        end
      end
    end
  end
end
