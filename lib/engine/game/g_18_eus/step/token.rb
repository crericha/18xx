# frozen_string_literal: true

require_relative '../../../step/token'
require_relative 'skip_bny'
require_relative 'skip_end_set'

module Engine
  module Game
    module G18EUS
      module Step
        class Token < Engine::Step::Token
          include SkipBny
          include SkipEndSet
        end
      end
    end
  end
end
