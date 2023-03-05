# frozen_string_literal: true

require_relative '../../../step/buy_train'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          include SkipBny
        end
      end
    end
  end
end
