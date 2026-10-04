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

          def actions(entity)
            return super unless @round.tokened
            return [] unless entity == current_entity

            extra_token_available?(entity) ? %w[pass] : []
          end

          def process_place_token(action)
            entity = action.entity

            if !@game.loading && !available_hex(entity, action.city.hex)
              raise GameError, "#{entity.name} cannot place token in City "\
                               "#{action.city.id} on hex #{action.city.hex.id}"
            end

            place_token(entity, action.city, action.token)
            pass! unless extra_token_available?(entity)
          end

          def extra_token_available?(entity)
            entity.companies.any? do |company|
              Array(@game.abilities(company, :token, time: 'any')).any? do |ability|
                ability.extra_action &&
                  @game.token_graph_for_entity(entity).can_token?(
                    entity,
                    cheater: ability.cheater,
                    tokens: [Engine::Token.new(entity)]
                  )
              end
            end
          end

          def can_place_token?(entity)
            return false if @round.tokened

            super || Array(@game.abilities(entity, :token, time: %w[%current_step% owner_corp_or_turn])).any? do |ability|
              @game.token_graph_for_entity(entity).can_token?(
                entity,
                cheater: ability.cheater,
                tokens: ability.from_owner ? entity.tokens_by_type : [Engine::Token.new(entity)]
              )
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
