# frozen_string_literal: true

require_relative '../../../step/token'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class Token < Engine::Step::Token
          include SkipBny
        end
      end
    end
  end
end
