# frozen_string_literal: true

require_relative '../../../step/buy_company'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class BuyCompany < Engine::Step::BuyCompany
          include SkipBny
        end
      end
    end
  end
end
