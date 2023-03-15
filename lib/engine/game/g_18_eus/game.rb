# frozen_string_literal: true

require_relative '../base'
require_relative 'meta'
require_relative 'map'
require_relative 'entities'
require_relative 'player'
require_relative 'market'

module Engine
  module Game
    module G18EUS
      class Game < Game::Base
        include_meta(G18EUS::Meta)
        include G18EUS::Entities
        include G18EUS::Map

        attr_reader :end_set

        include G18EUS::Market

        CERT_LIMIT = { 3 => 25, 4 => 20, 5 => 16 }.freeze

        STARTING_CASH = { 3 => 400, 4 => 300, 5 => 250 }.freeze

        SELL_BUY_ORDER = :sell_buy
        CAPITALIZATION = :incremental
        BIDDING_BOX_PRIVATE_COUNT = 4
        BIDDING_TOKENS_PER_ACTION = 4
        BUY_SHARE_FROM_OTHER_PLAYER = true
        NEXT_SR_PLAYER_ORDER = :first_to_pass

        PLAYER_CLASS = G18EUS::Player

        HOME_TOKEN_TIMING = :par

        OBSOLETE_TRAINS_COUNT_FOR_LIMIT = false

        EBUY_PRES_SWAP = false
        CERT_LIMIT_COUNTS_BANKRUPTED = true
        BANKRUPTCY_ENDS_GAME_AFTER = :all_but_one
        CLOSED_CORP_TOKENS_REMOVED = false

        GAME_END_CHECK = { bankrupt: :immediate, final_phase: :one_more_full_or_set, stock_market: :current_or }.freeze

        MARKET_TEXT = Base::MARKET_TEXT.merge(
          par: 'Par available SR1+',
          par_1: 'Par available SR2+',
          par_2: 'Par available SR3+',
          ignore_sale_unless_pres: 'Stock price does not change on sale, unless by president',
          endgame: 'End game trigger'
        ).freeze

        STOCKMARKET_COLORS = Base::STOCKMARKET_COLORS.merge(
          par: :yellow,
          par_1: :lightblue,
          par_2: :blue,
          ignore_sale_unless_pres: :violet,
          endgame: :red
        ).freeze

        PHASES = [
          {
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 2,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
          },
          {
            name: '5',
            on: '5',
            train_limit: 3,
            tiles: %i[yellow green brown],
            operating_rounds: 2,
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 2,
          },
          {
            name: '7',
            on: '7',
            train_limit: 2,
            tiles: %i[yellow green brown gray],
            operating_rounds: 2,
          },
          {
            name: '8',
            on: '4D',
            train_limit: 2,
            tiles: %i[yellow green brown gray],
            operating_rounds: 2,
          },
        ].freeze

        TRAINS = [
          { name: '2', distance: 2, price: 100, rusts_on: '4', num: 20 },
          { name: '2+', distance: 2, price: 100, obsolete_on: '4', num: 10 },
          { name: '3', distance: 3, price: 250, rusts_on: '6', num: 10 },
          { name: '3+', distance: 3, price: 250, obsolete_on: '6', num: 1 },
          { name: '4', distance: 4, price: 400, rusts_on: '8', num: 5 },
          { name: '4+', distance: 4, price: 400, obsolete_on: '8', num: 1 },
          { name: '5', distance: 5, price: 600, num: 3 },
          { name: '6', distance: 6, price: 750, num: 3 },
          {
            name: '7',
            distance: 7,
            price: 850,
            num: 2,
            variants: [
              name: '3D',
              distance: [{ 'nodes' => %w[city offboard], 'pay' => 3, 'visit' => 3, 'multiplier' => 2 }],
              price: 850,
            ],
          },
          {
            name: '4D',
            distance: [{ 'nodes' => %w[city offboard], 'pay' => 4, 'visit' => 4, 'multiplier' => 2 }],
            price: 1100,
            num: 40,
            events: [{ 'type' => 'signal_end_set' }],
          },
        ].freeze

        EVENTS_TEXT = Base::EVENTS_TEXT.merge('signal_end_set' => ['Signal End Set', 'End Set begins at SR']).freeze

        POTENTIAL_RED_CITY_HEXES = [
          { hex_id: 'E7', RA: 3, RB: 0, RC: 1 },
          { hex_id: 'E11', RA: 3, RB: 5, RC: 2 },
          { hex_id: 'F4', RA: 3, RB: 1, RC: 2 },
          { hex_id: 'G7', RA: 3, RB: 4, RC: 3 },
          { hex_id: 'H6', RA: 3, RB: 1, RC: 3 },
          { hex_id: 'H12', RA: 3, RB: 4, RC: 0 },
          { hex_id: 'I9', RA: 3, RB: 4, RC: 3 },
        ].freeze

        POTENTIAL_METROPOLIS_HEXES = %w[D8 F8 F14 J8].freeze

        REVENUE_MARKERS = %w[
          yellow_10|green_20|brown_30|gray_40
          yellow_10|green_40|brown_70|gray_100
          yellow_20|green_30|brown_40|gray_50
          yellow_20|green_30|brown_40|gray_40
          yellow_20|green_40|brown_50|gray_60
          yellow_20|green_40|brown_50|gray_70
          yellow_20|green_40|brown_70|gray_100
          yellow_30|green_40|brown_50|gray_60
          yellow_30|green_40|brown_60|gray_80
          yellow_30|green_50|brown_60|gray_80
          yellow_30|green_50|brown_70|gray_90
          yellow_30|green_40|brown_50|gray_60
          yellow_40|green_50|brown_40|gray_30
          yellow_40|green_50|brown_60|gray_70
          yellow_10|green_20|brown_30|gray_40
          yellow_20|green_30|brown_40|gray_40
        ].freeze

        def timeline
          @timeline ||= [
            'End of OR 1.1: All unsold 2 trains are exported.',
            'End of OR 1.2: All unsold 2+ trains are exported.',
            'End of OR 2.1: No trains are exported',
            'End of OR 2.2: All unsold 3 trains are exported',
            'End of each subsequent OR: The next available train is exported', \
            '*Exported trains are removed from the game and can trigger phase changes as if purchased',
          ].freeze
        end

        def ipo_name(_entity = nil)
          'Treasury'
        end

        def setup
          setup_tiles
          randomize_setup
          setup_privates
          setup_bny
        end

        def par_types_for_round
          %i[par par_1 par_2 par_3][0...@turn]
        end

        def bidding_token_per_player
          self.class::BIDDING_BOX_PRIVATE_COUNT
        end

        def setup_tiles
          @neutral_corp = Corporation.new(
            sym: 'N',
            name: 'Neutral',
            logo: '18_eus/black',
            simple_logo: '18_eus/black',
            tokens: [],
          )
          @neutral_corp.owner = @bank

          tiles = %w[G11 L10].map { |hex_id| hex_by_id(hex_id).tile }
          # Put a neutral token on the first of each pair of red cities
          tiles += RED_CITY_TILE_NAMES.map { |tile_name| @tiles.find { |tile| tile.name == tile_name } }
          tiles.each do |tile|
            token = Token.new(@neutral_corp, price: 0, type: :neutral)
            @neutral_corp.tokens << token
            tile.cities.first.place_token(@neutral_corp, token, check_tokenable: false)
          end
        end

        def randomize_setup
          randomize_map
        end

        def randomize_map
          randomize_cities
          randomize_offboard_revenues
          randomize_subsidies
        end

        def randomize_cities
          red_city_tiles = @tiles.select { |tile| self.class::RED_CITY_TILE_NAMES.include?(tile.name) }
          red_city_tiles = red_city_tiles.sort_by { rand }.take(3)

          selected_cities = self.class::POTENTIAL_RED_CITY_HEXES.sort_by { rand }.take(3)
          selected_cities.each do |selected_city|
            hex = hex_by_id(selected_city[:hex_id])
            tile = red_city_tiles.shift
            rotation = selected_city[tile.name.to_sym]
            tile.rotate!(rotation)
            hex.lay(tile)
          end

          metropolis_hex = hex_by_id(self.class::POTENTIAL_METROPOLIS_HEXES.min_by { rand })
          metropolis_tile = @tiles.find { |tile| tile.name == self.class::METROPOLIS_TILE_NAME }
          metropolis_hex.lay(metropolis_tile)
        end

        def randomize_offboard_revenues
          markers = self.class::REVENUE_MARKERS.sort_by { rand }.dup
          @hexes.each do |hex|
            hex.tile.nodes.first.parse_revenue(markers.shift) if hex.tile.color == :red
          end
        end

        def init_stock_market
          StockMarket.new(self.class::MARKET, [], zigzag: true)
        end

        def next_round!
          @round =
            case @round
            when G18EUS::Round::FinalBuild
              new_operating_round
            when Engine::Round::Stock
              @operating_rounds = @final_operating_rounds || @phase.operating_rounds
              reorder_players
              if @end_set
                new_final_build_round
              else
                new_operating_round
              end
            when Engine::Round::Operating
              export_train!
              if @round.round_num < @operating_rounds
                new_operating_round(@round.round_num + 1)
              else
                @turn += 1
                or_set_finished
                @end_set = true if final_phase?
                new_stock_round
              end
            end
        end

        def export_train!
          turn = "#{@turn}.#{@round.round_num}"
          case turn
          when '1.1'
            @depot.export_all!('2')
          when '1.2'
            @depot.export_all!('2+')
            @phase.next! unless @phase.tiles.include?(:green)
          when '2.2'
            @depot.export_all!('3')
          else
            @depot.export! if turn != '2.1' && !final_phase?
          end
        end

        def final_phase?
          @phase&.phases&.last == @phase&.current
        end

        def init_round
          stock_round
        end

        def stock_round
          G18EUS::Round::Stock.new(self, [
            Engine::Step::DiscardTrain,
            G18EUS::Step::HomeToken,
            G18EUS::Step::BuySellParShares,
          ])
        end

        def operating_round(round_num)
          Engine::Round::Operating.new(self, [
            G18EUS::Step::Bankrupt,
            Engine::Step::Exchange,
            Engine::Step::DiscardTrain,
            G18EUS::Step::SpecialTrack,
            Engine::Step::AcquireCompany,
            G18EUS::Step::Track,
            G18EUS::Step::Token,
            G18EUS::Step::Route,
            G18EUS::Step::Dividend,
            G18EUS::Step::BuyTrain,
            G18EUS::Step::IssueShares,
          ], round_num: round_num)
        end

        def new_final_build_round
          @log << '-- Final Build --'
          G18EUS::Round::FinalBuild.new(self, [
            G18EUS::Step::SpecialTrack,
            G18EUS::Step::Track,
            G18EUS::Step::Token,
          ])
        end

        def export_train
          turn = "#{@turn}.#{@round.round_num}"
          case turn
          when '1.1'
            @depot.export_all!('2')
          when '1.2'
            @depot.export_all!('2+')
            @phase.next! unless @phase.tiles.include?(:green)
          when '2.2'
            @depot.export_all!('3')
          else
            @depot.export! if turn != '2.1' && !game_end_check
          end
        end

        def a8_revenue_marker
          @a8_revenue_marker ||= 'yellow_40|green_60|brown_80|gray_100'
        end

        #
        # Subsidies
        #
        def randomize_subsidies
          subsidy_hexes = @hexes.select do |hex|
            hex.tile.color == :white &&
            !hex.tile.cities.empty? &&
            hex.id != self.class::CHICAGO_HEX_ID
          end
          subsidy_tiles = subsidy_hexes.map(&:tile).sort_by { rand }.take(5)

          subsidies = self.class::SUBSIDIES.sort_by { rand }.take(subsidy_tiles.size)

          @subsidies_by_hex = {}
          subsidy_tiles.zip(subsidies).each do |tile, subsidy|
            @subsidies_by_hex[tile.hex] = subsidy
            tile.icons << Engine::Part::Icon.new(subsidy[:icon])
          end
        end

        def claim_subsidy(corporation, hex)
          return unless hex.tile.color == :white
          return unless (subsidy = @subsidies_by_hex.delete(hex))

          hex.tile.icons.reject! { |icon| icon.name.include?('subsidy') }
          subsidy_company = create_company_from_subsidy(subsidy)
          subsidy_company.owner = corporation
          corporation.companies << subsidy_company
          apply_subsidy(subsidy_company)
        end

        def create_company_from_subsidy(subsidy)
          company = Engine::Company.new(**subsidy)
          @companies << company
          update_cache(:companies)
          company
        end

        def apply_subsidy(subsidy_company)
          corporation = subsidy_company.owner
          if subsidy_company.value.positive?
            @log << "#{corporation.name} receives #{format_currency(subsidy_company.value)} from subsidy"
            @bank.spend(subsidy_company.value, corporation)
            subsidy_company.close!
          elsif subsidy_company.sym == 'S0'
            subsidy_company.owner.tokens.first.hex.tile.icons << Engine::Part::Icon.new('18_eus/plus_ten', 'plus_ten', true)
            subsidy_company.close!
          elsif subsidy_company.sym == 'S9'
            subsidy_company.all_abilities.each do |ability|
              ability.hexes << corporation.tokens.first.hex.id if ability.type == :tile_lay
              ability.corporation = corporation.id if ability.type == :close
            end
          end
        end

        def remove_subsidy(hex)
          return unless (subsidy = @subsidies_by_hex.delete(hex))

          @log << "#{subsidy[:name]} subsidy removed from #{hex.coordinates} (#{hex.location_name})"
          hex.tile.icons.reject! { |icon| icon.image.include?(subsidy[:icon]) }
        end

        def float_str(_entity)
          '2 shares to start'
        end

        def grow_corporation(corporation)
          raise GameError, "#{corporation.name} is already a 10 share corporation" if corporation.total_shares.size == 10

          shares = corporation.share_holders.keys.flat_map { |sh| sh.shares_of(corporation) }
          shares.each { |share| share.percent = share.president ? 20 : 10 }
          5.times do |index|
            share = Share.new(corporation, owner: corporation.ipo_owner, percent: 10, index: 5 + index)
            corporation.ipo_owner.shares_by_corporation[corporation] << share
          end
          corporation.share_holders.keys do |sh|
            corporation.share_holders[sh] = sh.shares_by_corporation[corporation].sum(&:percent)
          end
          update_cache(:shares)
        end

        def home_token_locations(corporation)
          hexes.select do |hex|
            hex.tile.cities.any? { |city| city.tokenable?(corporation, free: true) }
          end
        end

        def after_par(corporation)
          return unless corporation.tokens.first.hex

          claim_subsidy(corporation, corporation.tokens.first.hex)
          consent_for_home_hex(corporation)
        end

        def payout_companies(ignore: [])
          return if @round.is_a?(G18EUS::Round::FinalBuild)

          super
        end

        FINAL_BUILD_TILE_LAYS = [
          { lay: true, upgrade: true, cost: 0 },
          { lay: true, upgrade: true, cost: 0 },
        ].freeze

        def tile_lays(_entity)
          @round.is_a?(G18EUS::Round::FinalBuild) ? FINAL_BUILD_TILE_LAYS : super
        end

        def consent_for_home_hex(corporation)
          home_hex = corporation.tokens.first.hex
          return unless home_hex.tile.color == :white

          company = self.class::COMPANY_CLASS.new(
            name: 'Home Hex Consent',
            desc: 'Other corporations cannot lay on home hex without consent. Closes after corporation operates.',
            sym: "#{corporation.id}-0",
            value: 0,
            abilities: [
              {
                type: 'blocks_hexes_consent',
                hexes: [home_hex.id],
              },
              {
                type: 'close',
                when: 'operated',
                corporation: corporation.id,
                silent: true,
              },
            ],
          )
          @companies << company

          company.owner = corporation
          company
        end

        def setup_privates
          @companies.sort_by! { rand }
          privates = @companies.group_by { |p| p.id[0] }
          privates.each do |group, comps|
            comps.rotate!(comps.index { |c| c.id == "#{group}0" })
          end

          @companies = privates.values.sort.map { |v| v.first(4) }.flatten
        end

        def bidbox_privates
          @companies.select { |c| (!c.owner || c.owner == @bank) && !c.closed? }.first(self.class::BIDDING_BOX_PRIVATE_COUNT)
        end

        def setup_bidboxes
          bidbox_privates.each { |c| c.owner = @bank }
        end

        def company_status_str(company)
          index = bidbox_privates.index(company)
          return "Bid box #{index + 1}" if index && index < self.class::BIDDING_BOX_PRIVATE_COUNT
        end

        def revenue_for(route, stops)
          raise GameError, 'Route visits same hex twice' if route.hexes.size != route.hexes.uniq.size

          super
        end

        def issuable_shares(entity)
          return [] if entity.num_ipo_shares.zero? || entity.operating_history.size <= 1

          issuable_bundles(entity)
        end

        def emergency_issuable_bundles(entity)
          issuable_bundles(entity)
        end

        def reduced_bundle_price_for_market_drop(bundle)
          directions = Array.new(bundle.num_shares, :left)
          bundle.share_price = @stock_market.find_share_price(bundle.corporation, directions).price
          bundle
        end

        def redeemable_shares(entity)
          bundles_for_corporation(@share_pool, entity).reject { |bundle| entity.cash < bundle.price }
        end

        def event_signal_end_set!
          @log << "-- Event: #{EVENTS_TEXT['signal_end_set'][1]} --"
        end

        def operating_order
          super.partition { |corp| corp != bny }.flatten
        end

        def bny
          @bny ||= @corporations.find { |c| c.type == :bank }
        end

        def setup_bny
          stock_market.set_par(bny, stock_market.par_prices.find { |pp| pp.price == 80 })
          bny.ipoed = true
          bny.owner = @share_pool
          setup_loans
        end

        def setup_loans
          @loans =
            case @players.size
            when 3
              [
                { stock_movement: :diagonal, multipliers: [0.5, 1, 1, 1.5, 1.5, 2, nil, nil] },
                { stock_movement: :straight, multipliers: [2, 2, 2, 2.5, 2.5, 2.5, 3, 3] },
                { stock_movement: :diagonal_and_straight, multipliers: [3, 3, 3.5, 3.5, 3.5, 3.5, 4, 4] },
                { stock_movement: :diagonal_and_straight, multipliers: [4, 4, 5, 5, 5, 5, 5, 5] },
              ]
            when 4
              [
                { stock_movement: :diagonal, multipliers: [0.5, 0.5, 1, 1, 1.5, 1.5, 2, nil, nil] },
                { stock_movement: :straight, multipliers: [2, 2, 2.5, 2.5, 2.5, 3, 3.nil, nil] },
                { stock_movement: :diagonal_and_straight, multipliers: [3, 3, 3, 3.5, 3.5, 3.5, 3.5, 3.5, nil] },
                { stock_movement: :diagonal_and_straight, multipliers: [3.5, 3.5, 4, 4, 4, 4, 4, 4, 4] },
                { stock_movement: :diagonal_and_straight, multipliers: [5, 5, 5, 5, 5, 5, 5, 5, 5] },
              ]
            when 5
              [
                { stock_movement: :diagonal, multipliers: [0.5, 0.5, 1, 1, 1.5, 1.5, 1.5, 2, nil, nil] },
                { stock_movement: :straight, multipliers: [2, 2, 2, 2.5, 2.5, 2.5, 3, 3, nil, nil] },
                { stock_movement: :diagonal_and_straight, multipliers: [3, 3, 3, 3, 3.5, 3.5, 3.5, 3.5, 3.5, 4] },
                { stock_movement: :diagonal_and_straight, multipliers: [4, 4, 4, 4, 4, 4, 4, 5, 5, 5] },
                { stock_movement: :diagonal_and_straight, multipliers: [5, 5, 5, 5, 5, 5, 5, 5, 5, 5] },
              ]
            end
          @loans_map = [nil]
          @loans.each.with_index do |row, row_index|
            row[:multipliers].each.with_index do |value, col_index|
              @loans_map << { row: row_index, col: col_index } if value
            end
          end
          @loans_taken = 0
        end

        def loan_chart
          last_loan_taken = @loans_map[@loans_taken]
          loan_chart = []
          @loans.each.with_index do |row, row_index|
            header = loan_movement_to_arrows(row[:stock_movement])
            loans = []
            row[:multipliers].each.with_index do |value, col_index|
              loans << ({ value: value, loan_taken: loan_taken?(last_loan_taken, row_index, col_index) } if value)
            end
            loan_chart << { header: header, loans: loans }
          end
          loan_chart
        end

        def loan_taken?(last_loan_taken, row_index, col_index)
          return false unless last_loan_taken
          return true if last_loan_taken[:row] > row_index
          return true if last_loan_taken[:row] == row_index && last_loan_taken[:col] >= col_index

          false
        end

        def loan_movement_to_arrows(movement)
          case movement
          when :diagonal
            '↗'
          when :straight
            '→'
          when :diagonal_and_straight
            '→↗'
          end
        end

        def current_loan_multiplier
          return 0 if @loans_taken.zero?

          loan_row = @loans_map[@loans_taken][:row]
          loan_col = @loans_map[@loans_taken][:col]
          @loans[loan_row][:multipliers][loan_col]
        end

        def current_loan_movement
          @loans_taken.zero? ? :none : @loans[@loans_map[@loans_taken][:row]][:stock_movement]
        end

        def loan_entity_name
          'Bank of New York'
        end

        def max_player_loans
          case @turn
          when 1 then 4
          when 2 then 6
          when 3 then 8
          else 10
          end
        end

        def player_loans(player)
          player.loans
        end

        def can_take_loan?(player)
          player.loans < max_player_loans && !bny.player_share_holders[player]&.positive?
        end

        def can_payoff_loan?(player)
          player.loans.positive? && player.cash >= bny.share_price.price
        end

        def take_loan(player)
          amount = loan_amount
          @log << "#{player.name} takes a loan and receives #{format_currency(amount)}"
          player.take_loan!
          bank.spend(amount, player)
          @loans_taken += 1
        end

        def payoff_loan(player)
          amount = loan_amount
          @log << "#{player.name} repays a loan for #{format_currency(amount)}"
          player.repay_loan!
          player.spend(amount, bank)
          @loans_taken -= 1
        end

        def loan_amount
          bny.share_price.price
        end

        def sold_shares_destination(entity)
          entity == bny ? :corporation : super
        end

        def sell_shares_and_change_price(bundle, allow_president_change: true, swap: nil)
          bundle.corporation == bny ? @share_pool.sell_shares(bundle, allow_president_change: false, swap: swap) : super
        end

        def routes_revenue(routes)
          @round.current_entity == bny ? bny.share_price.info.to_i * current_loan_multiplier * 10 : super
        end

        private

        def issuable_bundles(entity)
          bundles_for_corporation(entity, entity)
            .select { |bundle| @share_pool.fit_in_bank?(bundle) }
            .map { |bundle| reduced_bundle_price_for_market_drop(bundle) }
        end
      end
    end
  end
end
