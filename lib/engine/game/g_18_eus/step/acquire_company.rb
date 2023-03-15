# frozen_string_literal: true

require_relative '../../../step/acquire_company'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class AcquireCompany < Engine::Step::AcquireCompany
          include SkipBny
        end
      end
    end
  end
end
