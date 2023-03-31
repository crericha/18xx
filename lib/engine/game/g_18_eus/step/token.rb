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

          def can_place_token?(entity)
            return false if @round.tokened

            super || Array(@game.abilities(entity, :token, time: %w[%current_step% owner_corp_or_turn])).any? do |ability|
              @game.token_graph_for_entity(entity).can_token?(entity, cheater: ability.cheater)
            end
          end

          def log_skip(entity)
            super unless @round.tokened
          end
        end
      end
    end
  end
end
