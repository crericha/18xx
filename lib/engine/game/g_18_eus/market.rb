# frozen_string_literal: true

require_relative 'map'

module Engine
  module Game
    module G18EUS
      module Market
        MARKET = [
          [
            { price: 40, types: [] },
            { price: 44, types: [] },
            { price: 47, types: [] },

            { price: 50, types: [:par] },
            { price: 53, types: [:par] },
            { price: 57, types: [:par] },
            { price: 61, types: [:par] },
            { price: 65, types: [:par] },
            { price: 70, types: [:par] },
            { price: 75, types: [:par] },

            { price: 80, types: [:par], info: '12' },
            { price: 86, types: [:par], info: '12' },
            { price: 92, types: [:par], info: '14' },
            { price: 98, types: [:par], info: '14' },

            { price: 105, types: [:par_1], info: '16' },
            { price: 112, types: [:par_1], info: '16' },
            { price: 120, types: [:par_1], info: '18' },
            { price: 128, types: [:par_1], info: '18' },
            { price: 137, types: [:par_1], info: '20' },
            { price: 147, types: [:par_1], info: '20' },
            { price: 157, types: [:par_1], info: '22' },

            { price: 168, types: [:par_2], info: '22' },
            { price: 180, types: [:par_2], info: '24' },
            { price: 193, types: [:par_2], info: '26' },
            { price: 206, types: [:par_2], info: '28' },

            { price: 221, types: [], info: '30' },
            { price: 236, types: [], info: '32' },
            { price: 253, types: [], info: '34' },
            { price: 270, types: [], info: '38' },
            { price: 289, types: [], info: '40' },
            { price: 310, types: [], info: '40' },
            { price: 331, types: [], info: '40' },
            { price: 354, types: [], info: '40' },
            { price: 379, types: [], info: '50' },

            { price: 406, types: [:ignore_sale_unless_pres], info: '50' },
            { price: 434, types: [:ignore_sale_unless_pres], info: '50' },
            { price: 465, types: [:ignore_sale_unless_pres], info: '50' },
            { price: 497, types: [:ignore_sale_unless_pres], info: '60' },
            { price: 532, types: [:ignore_sale_unless_pres], info: '60' },
            { price: 569, types: [:ignore_sale_unless_pres], info: '60' },
            { price: 609, types: [:ignore_sale_unless_pres], info: '70' },
            { price: 652, types: [:ignore_sale_unless_pres], info: '70' },
            { price: 700, types: [:ignore_sale_unless_pres], info: '70' },

            { price: 750, types: [:endgame] },
            { price: 800, types: [:endgame] },
          ],
        ].freeze
      end
    end
  end
end
