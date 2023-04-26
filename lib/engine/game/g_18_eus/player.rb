# frozen_string_literal: true

require_relative '../../player'

module Engine
  module Game
    module G18EUS
      class Player < Engine::Player
        attr_accessor :loans

        def initialize(id, name)
          @loans = 0
          super
        end

        def value
          @cash + shares.select { |s| s.corporation.ipoed }.sum(&:price)
        end

        def take_loan!
          @loans += 1
        end

        def repay_loan!
          @loans -= 1
        end
      end
    end
  end
end
