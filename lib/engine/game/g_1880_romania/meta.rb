# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G1880Romania
      module Meta
        include Game::Meta

        DEV_STAGE = :alpha
        DEPENDS_ON = '1880'

        GAME_DESIGNER = 'Lonny Orgler'
        GAME_INFO_URL = 'https://github.com/tobymao/18xx/wiki/1880-Romania'
        GAME_LOCATION = 'Romania'
        GAME_PUBLISHER = :lonny_games
        GAME_RULES_URL = 'https://www.lonnygames.com/downloads/'
        GAME_TITLE = '1880 Romania'

        PLAYER_RANGE = [3, 6].freeze

        OPTIONAL_RULES = [
          {
            sym: :kingdom_of_romania,
            short_name: "Kingdom of Romania",
            desc: "Smaller map",
            players: [2,3],
          },
        ].freeze
      end
    end
  end
end
