# frozen_string_literal: true

require 'spec_helper'

describe Engine::Game::G18EUS::Game do
  describe 'red city tile setup' do
    def red_city_tiles(game)
      game.hexes.map(&:tile).select { |tile| %w[RA RB RC].include?(tile.name) }
    end

    def closed_count(game)
      red_city_tiles(game).count { |tile| tile.cities.first.tokened? }
    end

    it 'lays 2 open-token tiles and 1 closed-token tile' do
      (1..20).each do |seed|
        game = described_class.new(%w[a b c], seed: seed)

        expect(red_city_tiles(game).size).to eq(3)
        expect(closed_count(game)).to eq(1)
      end
    end

    it 'lays 3 open-token tiles with the tighter tokening variant' do
      (1..20).each do |seed|
        game = described_class.new(%w[a b c], seed: seed, optional_rules: %i[tighter_tokening])

        expect(red_city_tiles(game).size).to eq(3)
        expect(closed_count(game)).to eq(0)
      end
    end
  end

  describe 'player loans' do
    let(:game) do
      game = described_class.new(%w[a b c])
      # pass through the initial private auction to reach the first stock round
      while game.round.is_a?(Engine::Game::G18EUS::Round::Auction)
        game.process_action(Engine::Action::Pass.new(game.current_entity))
      end
      game
    end
    let(:player) { game.current_entity }
    let(:loan_amount) { game.loan_amount }

    it 'includes available loans in liquidity' do
      expect(game.liquidity(player)).to eq(player.cash + (game.max_player_loans * loan_amount))
    end

    it 'reports the loan portion of liquidity via available_loan_funds' do
      expect(game.available_loan_funds(player)).to eq(game.max_player_loans * loan_amount)
      expect(game.liquidity(player, emergency: true)).to eq(player.cash + game.available_loan_funds(player))
    end

    it 'excludes loans from liquidity after paying off a loan in the stock round' do
      player.take_loan!
      game.loans_taken += 1

      game.process_action(Engine::Action::PayoffLoan.new(player, loan: nil))

      expect(game.can_take_loan?(player)).to be(false)
      expect(game.liquidity(player)).to eq(player.cash)
    end

    it 'excludes loans from liquidity after buying a Bank of New York share' do
      bundle = game.bny.treasury_shares.first.to_bundle
      game.process_action(Engine::Action::BuyShares.new(player, shares: bundle.shares))

      expect(game.can_take_loan?(player)).to be(false)
      expect(game.liquidity(player)).to eq(player.cash)
    end
  end

  describe '#player_status_str' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:player) { game.current_entity }

    def reach_stock_round(game)
      game.process_action(Engine::Action::Pass.new(game.current_entity)) until game.round.stock?
    end

    it 'shows nothing during the initial auction' do
      expect(game.player_status_str(player)).to be_nil
    end

    it 'shows neutral when the player has not taken a loan, repaid a loan, or bought a BNY share' do
      reach_stock_round(game)

      expect(game.player_status_str(player)).to eq('Status: Neutral')
    end

    it 'shows Sell Bank / Take Loans after the player takes a loan' do
      reach_stock_round(game)
      game.process_action(Engine::Action::TakeLoan.new(player, loan: nil))

      expect(game.player_status_str(player)).to eq('Status: Sell Bank / Take Loans')
    end

    it 'shows Buy bank / Pay off loan after the player repays a loan' do
      reach_stock_round(game)
      player.take_loan!
      game.loans_taken += 1
      game.process_action(Engine::Action::PayoffLoan.new(player, loan: nil))

      expect(game.player_status_str(player)).to eq('Status: Buy bank / Pay off loan')
    end

    it 'shows Buy bank / Pay off loan after the player buys a BNY share' do
      reach_stock_round(game)
      bundle = game.bny.treasury_shares.first.to_bundle
      game.process_action(Engine::Action::BuyShares.new(player, shares: bundle.shares))

      expect(game.player_status_str(player)).to eq('Status: Buy bank / Pay off loan')
    end

    it 'shows Sell Bank / Take Loans after the player sells a BNY share' do
      reach_stock_round(game)
      game.share_pool.transfer_shares(game.bny.treasury_shares.first.to_bundle, player)
      bundle = player.shares_of(game.bny).first.to_bundle
      game.process_action(Engine::Action::SellShares.new(player, shares: bundle.shares))

      expect(game.player_status_str(player)).to eq('Status: Sell Bank / Take Loans')
    end

    it 'only reflects the acting player' do
      reach_stock_round(game)
      other = game.players.find { |p| p != player }
      game.process_action(Engine::Action::TakeLoan.new(player, loan: nil))

      expect(game.player_status_str(other)).to eq('Status: Neutral')
    end
  end

  describe 'stock round programmed actions' do
    let(:game) do
      game = described_class.new(%w[a b c])
      # pass through the initial private auction to reach the first stock round
      while game.round.is_a?(Engine::Game::G18EUS::Round::Auction)
        game.process_action(Engine::Action::Pass.new(game.current_entity))
      end
      game
    end
    let(:president) { game.round.entities[0] }
    let(:buyer) { game.round.entities[1] }
    let(:third) { game.round.entities[2] }
    let(:corporation) do
      # a floated corporation whose president holds 80%, the third player 20%,
      # with an empty IPO and market, so the president's shares can be bought
      corp = game.corporations.find { |c| c != game.bny && c != game.auction_corporation }
      game.stock_market.set_par(corp, game.stock_market.par_prices.max_by(&:price))
      corp.ipoed = true
      city = game.hexes.find { |h| h.tile.cities.any? { |c| c.tokenable?(corp, free: true) } }.tile.cities.first
      city.place_token(corp, corp.next_token, free: true)
      game.share_pool.transfer_shares(corp.ipo_shares.find(&:president).to_bundle, president)
      2.times { game.share_pool.transfer_shares(corp.ipo_shares.first.to_bundle, president) }
      game.share_pool.transfer_shares(corp.ipo_shares.first.to_bundle, third)
      corp
    end
    let(:step) { game.round.active_step }

    def buy_from_president(player)
      share = president.shares_of(corporation).reject(&:president).first
      price = step.modify_purchase_price(share.to_bundle)
      game.process_action(Engine::Action::BuyShares.new(player, shares: [share], share_price: price),
                          add_auto_actions: true)
    end

    # an unrelated purchase that keeps the stock round from ending on consecutive passes
    def buy_bny(player)
      share = game.bny.treasury_shares.first
      game.process_action(Engine::Action::BuyShares.new(player, shares: [share]), add_auto_actions: true)
    end

    def enable_auto_pass_and_pass(player)
      game.process_action(Engine::Action::ProgramSharePass.new(player))
      game.process_action(Engine::Action::Pass.new(player), add_auto_actions: true)
    end

    describe 'auto pass' do
      it 'stops when another player buys one of your shares' do
        corporation
        enable_auto_pass_and_pass(president)
        buy_from_president(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::ProgramDisable])
        expect(pass.auto_actions.first.reason).to eq("#{buyer.name} bought a share of #{corporation.name} from #{president.name}")
        expect(game.programmed_actions[president]).to be_empty
        expect(game.current_entity).to eq(president)
      end

      it 'keeps passing when nobody buys your shares' do
        corporation
        enable_auto_pass_and_pass(president)
        buy_bny(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::Pass])
        expect(game.programmed_actions[president]).not_to be_empty
      end

      it 'ignores shares bought from you before auto pass was enabled' do
        corporation
        game.process_action(Engine::Action::Pass.new(president), add_auto_actions: true)
        buy_from_president(buyer)
        game.process_action(Engine::Action::Pass.new(third), add_auto_actions: true)
        enable_auto_pass_and_pass(president)
        buy_bny(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::Pass])
      end
    end

    describe 'auto payoff loans' do
      def give_loan(player)
        player.take_loan!
        game.loans_taken += 1
      end

      def enable_auto_payoff_and_pass(player)
        game.process_action(Engine::Action::ProgramPayoffLoans.new(player))
        game.process_action(Engine::Action::Pass.new(player), add_auto_actions: true)
      end

      it 'pays off a loan on your turn' do
        give_loan(president)
        enable_auto_payoff_and_pass(president)
        buy_bny(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::PayoffLoan])
        expect(president.loans).to eq(0)
        expect(game.programmed_actions[president]).not_to be_empty
        expect(game.current_entity).to eq(buyer)
      end

      it 'disables when you have no loans to pay off' do
        enable_auto_payoff_and_pass(president)
        buy_bny(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::ProgramDisable])
        expect(pass.auto_actions.first.reason).to eq('No loans to pay off')
        expect(game.programmed_actions[president]).to be_empty
        expect(game.current_entity).to eq(president)
      end

      it 'disables when you cannot afford to pay off a loan' do
        give_loan(president)
        enable_auto_payoff_and_pass(president)
        president.spend(president.cash - game.loan_amount + 1, game.bank)
        buy_bny(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::ProgramDisable])
        expect(pass.auto_actions.first.reason).to eq('Cannot afford to pay off a loan')
        expect(president.loans).to eq(1)
        expect(game.current_entity).to eq(president)
      end

      it 'disables when you took a loan this stock round' do
        game.process_action(Engine::Action::TakeLoan.new(president, loan: nil))
        enable_auto_payoff_and_pass(president)
        buy_bny(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::ProgramDisable])
        expect(pass.auto_actions.first.reason).to eq('Took a loan this stock round')
        expect(president.loans).to eq(1)
        expect(game.current_entity).to eq(president)
      end

      it 'stops when another player buys one of your shares' do
        corporation
        give_loan(president)
        enable_auto_payoff_and_pass(president)
        buy_from_president(buyer)

        pass = Engine::Action::Pass.new(third)
        game.process_action(pass, add_auto_actions: true)

        expect(game.exception).to be_nil
        expect(pass.auto_actions.map(&:class)).to eq([Engine::Action::ProgramDisable])
        expect(pass.auto_actions.first.reason).to eq("#{buyer.name} bought a share of #{corporation.name} from #{president.name}")
        expect(president.loans).to eq(1)
        expect(game.current_entity).to eq(president)
      end

      it 'is removed when the stock round ends' do
        give_loan(president)
        game.process_action(Engine::Action::ProgramPayoffLoans.new(president))
        game.round.entities.each { |p| game.process_action(Engine::Action::Pass.new(p)) }

        expect(game.round.stock?).to be(false)
        expect(game.programmed_actions[president]).to be_empty
      end
    end
  end

  describe 'city auction' do
    let(:game) do
      game = described_class.new(%w[a b c])
      # pass through the initial private auction to reach the first stock round
      while game.round.is_a?(Engine::Game::G18EUS::Round::Auction)
        game.process_action(Engine::Action::Pass.new(game.current_entity))
      end
      game
    end
    let(:a) { game.players.find { |p| p.name == 'a' } }
    let(:b) { game.players.find { |p| p.name == 'b' } }
    let(:c) { game.players.find { |p| p.name == 'c' } }

    def act(action)
      game.process_action(action)
      raise game.exception if game.exception
    end

    def bidder
      game.round.active_step.current_entity
    end

    # b starts an auction for a city location with a $0 opening bid
    def start_auction
      act(Engine::Action::Pass.new(a))
      act(Engine::Action::Choose.new(b, choice: 0))
      pending = game.round.pending_tokens.first
      act(Engine::Action::PlaceToken.new(pending[:entity], city: pending[:hexes].first.tile.cities.first, slot: 0))
      act(Engine::Action::Bid.new(b, corporation: game.auction_corporation, price: 0))
    end

    def par_and_pass(winner)
      corporation = game.corporations.find { |c| c != game.bny && c != game.auction_corporation }
      share_price = game.round.active_step.get_par_prices(winner, corporation).min_by(&:price)
      act(Engine::Action::Par.new(winner, corporation: corporation, share_price: share_price))
      act(Engine::Action::Choose.new(winner, choice: '5 share'))
      act(Engine::Action::Pass.new(winner))
    end

    it 'gives the starter another stock turn when another player wins' do
      start_auction
      act(Engine::Action::Bid.new(c, corporation: game.auction_corporation, price: 5))
      act(Engine::Action::Pass.new(a))
      act(Engine::Action::Pass.new(b))
      expect(bidder).to eq(c)

      par_and_pass(c)

      expect(game.current_entity).to eq(b)
      expect(game.round.actions_for(b)).to include('choose', 'buy_shares')
      expect(b.passed?).to be(false)
      expect(game.round.pass_order).not_to include(b)
    end

    it 'records a pass if the starter passes on the extra stock turn' do
      start_auction
      act(Engine::Action::Bid.new(c, corporation: game.auction_corporation, price: 5))
      act(Engine::Action::Pass.new(a))
      act(Engine::Action::Pass.new(b))
      par_and_pass(c)

      act(Engine::Action::Pass.new(b))

      expect(b.passed?).to be(true)
      expect(game.current_entity).to eq(c)
    end

    it 'rejects an opening bid that is not a multiple of $5' do
      act(Engine::Action::Pass.new(a))
      act(Engine::Action::Choose.new(b, choice: 0))
      pending = game.round.pending_tokens.first
      act(Engine::Action::PlaceToken.new(pending[:entity], city: pending[:hexes].first.tile.cities.first, slot: 0))

      game.process_action(Engine::Action::Bid.new(b, corporation: game.auction_corporation, price: 3))
      expect(game.exception).to be_a(Engine::GameError)
      expect(game.exception.message).to include('multiple of 5')
    end

    it 'rejects a raise that is not a multiple of $5' do
      start_auction

      game.process_action(Engine::Action::Bid.new(c, corporation: game.auction_corporation, price: 12))
      expect(game.exception).to be_a(Engine::GameError)
      expect(game.exception.message).to include('multiple of 5')
    end

    it 'accepts a raise that is a multiple of $5' do
      start_auction
      act(Engine::Action::Bid.new(c, corporation: game.auction_corporation, price: 15))

      expect(game.round.active_step.min_bid(game.auction_corporation)).to eq(20)
    end

    it 'moves to the next player when the starter wins' do
      start_auction
      act(Engine::Action::Pass.new(c))
      act(Engine::Action::Pass.new(a))
      expect(bidder).to eq(b)

      par_and_pass(b)

      expect(game.current_entity).to eq(c)
      expect(b.passed?).to be(false)
    end
  end

  describe 'private auction' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:company) { game.bidbox_privates.first }

    it 'rejects a bid that is not a multiple of $5' do
      game.process_action(Engine::Action::Bid.new(game.current_entity, company: company, price: company.min_bid + 3))

      expect(game.exception).to be_a(Engine::GameError)
      expect(game.exception.message).to include('multiple of 5')
    end

    it 'accepts a bid that is a multiple of $5' do
      game.process_action(Engine::Action::Bid.new(game.current_entity, company: company, price: company.min_bid + 10))

      expect(game.exception).to be_nil
      expect(game.round.active_step.min_bid(company)).to eq(company.min_bid + 15)
    end
  end

  describe 'bankruptcy' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:a) { game.players.find { |p| p.name == 'a' } }
    let(:b) { game.players.find { |p| p.name == 'b' } }
    let(:c) { game.players.find { |p| p.name == 'c' } }
    let(:corps) { game.corporations.reject { |corp| corp == game.bny } }
    let(:five_share) { corps[0] }
    let(:ten_share) { corps[1] }
    let(:other) { corps[2] }

    def float(corp)
      game.stock_market.set_par(corp, game.stock_market.par_prices.find { |pp| pp.price == 70 })
      corp.ipoed = true
    end

    def give(corp, player, count)
      count.times { game.share_pool.transfer_shares(corp.ipo_shares.first.to_bundle, player) }
    end

    def go_bankrupt(player)
      step = Engine::Game::G18EUS::Step::Bankrupt.new(game, game.round)
      step.process_bankrupt(Engine::Action::Bankrupt.new(player))
    end

    before do
      [five_share, ten_share, other].each { |corp| float(corp) }
      game.grow_corporation(ten_share)

      give(five_share, a, 1) # president's certificate (2 shares)
      give(five_share, b, 2)
      give(ten_share, a, 1) # president's certificate (2 shares)
      give(ten_share, b, 1)
      give(ten_share, c, 1)
      give(other, b, 1) # president's certificate (2 shares)
      give(other, a, 1)
      game.share_pool.transfer_shares(game.bny.treasury_shares.first.to_bundle, a, allow_president_change: false)
    end

    it "pays other holders of the bankrupt player's companies the current price per share" do
      b_cash = b.cash
      c_cash = c.cash

      go_bankrupt(a)

      expect(b.cash).to eq(b_cash + (70 * 2) + 70)
      expect(c.cash).to eq(c_cash + 70)
      expect(five_share).to be_closed
      expect(ten_share).to be_closed
      expect(game.share_pool.percent_of(five_share)).to eq(0)
    end

    it "moves the bankrupt player's remaining shares to the bank pool" do
      go_bankrupt(a)

      expect(a.shares).to be_empty
      expect(game.share_pool.percent_of(other)).to eq(20)
      expect(game.share_pool.percent_of(game.bny)).to eq(10)
      expect(other.owner).to eq(b)
      expect(other.share_price.price).to eq(70)
    end

    it 'returns loans, removes 3 more, and exports the top train' do
      2.times { a.take_loan! }
      game.loans_taken += 2
      top_train = game.depot.upcoming.first
      upcoming_size = game.depot.upcoming.size

      go_bankrupt(a)

      expect(a.loans).to eq(0)
      expect(game.loans_taken).to eq(3)
      expect(game.depot.upcoming.size).to eq(upcoming_size - 1)
      expect(game.depot.upcoming).not_to include(top_train)
      expect(a.cash).to eq(0)
      expect(a.bankrupt).to be(true)
    end
  end

  describe '#emergency_issuable_bundles' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:corp) { game.corporations.find { |c| c != game.bny } }

    before do
      game.stock_market.set_par(corp, game.stock_market.par_prices.find { |pp| pp.price == 70 })
      corp.ipoed = true
      game.share_pool.transfer_shares(corp.ipo_shares.first.to_bundle, game.players.first)
    end

    it 'offers no shares on the first operating turn' do
      corp.operating_history[[1, 1]] = nil

      expect(game.emergency_issuable_bundles(corp)).to be_empty
    end

    it 'offers shares after the first operating turn' do
      corp.operating_history[[1, 1]] = nil
      corp.operating_history[[1, 2]] = nil

      expect(game.emergency_issuable_bundles(corp)).not_to be_empty
    end
  end

  describe '#pullman_bonus_revenue' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:city) { game.hexes.flat_map { |hex| hex.tile.cities }.first }
    let(:rural_junction) { game.tiles.find { |t| t.name == 'X07' }.towns.first }

    it 'adds $20 per city' do
      expect(game.pullman_bonus_revenue([city])).to eq(20)
    end

    it 'does not add to rural junction stops' do
      expect(game.pullman_bonus_revenue([city, rural_junction])).to eq(20)
    end
  end

  describe 'Mail Contracts' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:corp) { game.corporations.find { |c| c != game.bny } }
    let(:routes) { [double('route', revenue: 150, train: double('train', owner: corp))] }

    def mail_contract(sym)
      company = game.late_bloomer_companies.find { |c| c.sym == sym }
      game.add_company_to_game(company) if company
      game.company_by_id(sym)
    end

    def acquire(company)
      company.owner = corp
      corp.companies << company
      game.company_bought(company, corp)
    end

    it 'keeps B1 open with no cash when bought' do
      b1 = mail_contract('B1')

      expect { acquire(b1) }.not_to(change { corp.cash })
      expect(b1).not_to be_closed
    end

    it 'adds 20% of train revenue for one Mail Contract' do
      acquire(mail_contract('B1'))

      expect(game.routes_subsidy(routes)).to eq(30)
    end

    it 'adds 20% per Mail Contract when a company owns both' do
      acquire(mail_contract('A2'))
      acquire(mail_contract('B1'))

      expect(game.routes_subsidy(routes)).to eq(60)
    end

    it 'rounds down' do
      acquire(mail_contract('A2'))
      odd_routes = [double('route', revenue: 157, train: double('train', owner: corp))]

      expect(game.routes_subsidy(odd_routes)).to eq(31)
    end

    it 'adds nothing for a company without a Mail Contract' do
      expect(game.routes_subsidy(routes)).to eq(0)
    end

    it 'adds nothing without routes' do
      acquire(mail_contract('A2'))

      expect(game.routes_subsidy([])).to eq(0)
    end
  end

  describe 'Late Bloomer' do
    let(:optional_rules) { [] }
    let(:game) { described_class.new(%w[a b c], optional_rules: optional_rules) }
    let(:corp) { game.corporations.find { |c| c != game.bny } }
    let(:late_bloomer) { game.late_bloomer }
    let(:step) { Engine::Game::G18EUS::Step::SpecialChoose.new(game, game.round) }

    before do
      game.stock_market.set_par(corp, game.stock_market.par_prices.find { |pp| pp.price == 70 })
      corp.ipoed = true
      game.share_pool.transfer_shares(corp.ipo_shares.first.to_bundle, game.players.first)
      late_bloomer.owner = corp
      corp.companies << late_bloomer
    end

    def choose(choice)
      step.process_choose_ability(Engine::Action::ChooseAbility.new(late_bloomer, choice: choice))
    end

    context 'with the expert version (default)' do
      it 'uses the expert Late Bloomer card' do
        expect(late_bloomer.desc).to include('Swap this private')
        expect(game.companies.count { |c| c.sym == 'A0' }).to eq(1)
      end

      it 'offers $400 and every unused private' do
        expect(step.choices_ability(late_bloomer).keys)
          .to eq(['LB-CASH', *game.late_bloomer_companies.map(&:sym).sort])
        expect(game.late_bloomer_companies.size).to eq(18)
      end

      it 'shows each choice as a company card' do
        cards = step.choices_ability_companies(late_bloomer)

        expect(cards.keys).to eq(step.choices_ability(late_bloomer).keys)
        expect(cards['LB-CASH'].name).to eq('$400')
        expect(cards.values.drop(1)).to eq(game.late_bloomer_companies.sort_by(&:sym))
      end

      it 'swaps for an unused private' do
        company = game.late_bloomer_companies.first

        choose(company.sym)

        expect(company.owner).to eq(corp)
        expect(game.companies).to include(company)
        expect(late_bloomer).to be_closed
      end

      it 'pays $400 into the treasury' do
        expect { choose('LB-CASH') }.to change { corp.cash }.by(400)
        expect(late_bloomer).to be_closed
      end

      it 'rejects an unknown choice' do
        expect { choose('LB-LOANS') }.to raise_error(Engine::GameError)
      end

      it 'keeps the fake choice cards out of the game companies' do
        step.choices_ability_companies(late_bloomer)

        expect(game.companies.map(&:sym)).not_to include('LB-CASH', 'LB-2P', 'LB-LOANS')
      end
    end

    context 'with the standard version' do
      let(:optional_rules) { %i[standard_late_bloomer] }

      it 'uses the standard Late Bloomer card' do
        expect(late_bloomer.desc).to include('picks one of three options')
        expect(game.companies.count { |c| c.sym == 'A0' }).to eq(1)
      end

      it 'offers a permanent 2-train, $400, or removing 2 loans' do
        expect(step.choices_ability(late_bloomer).keys).to eq(%w[LB-2P LB-CASH LB-LOANS])
        expect(step.choices_ability_companies(late_bloomer).values.map(&:sym)).to eq(%w[LB-2P LB-CASH LB-LOANS])
      end

      it 'gives a permanent 2-train and leaves one for C2' do
        choose('LB-2P')

        expect(corp.trains.map(&:name)).to eq(['2P'])
        expect(game.depot.trains.count { |t| t.name == '2P' && t.owner == game.depot }).to eq(1)
        expect(late_bloomer).to be_closed
      end

      it 'pays $400 into the treasury' do
        expect { choose('LB-CASH') }.to change { corp.cash }.by(400)
      end

      it 'removes 2 loans and moves the Bank of New York one space' do
        row, column = game.bny.share_price.coordinates
        game.loans_taken = 1

        choose('LB-LOANS')

        expect(game.loans_taken).to eq(3)
        expect(game.bny.share_price.coordinates).to eq([row, column + 1])
        expect(late_bloomer).to be_closed
      end

      it 'removes only the loans that are left' do
        game.loans_taken = game.total_loans - 1

        choose('LB-LOANS')

        expect(game.loans_taken).to eq(game.total_loans)
      end
    end
  end

  describe 'Bank Lobbyist' do
    let(:game) { described_class.new(%w[a b c]) }
    let(:corp) { game.corporations.find { |c| c != game.bny } }
    let(:president) { game.players.first }
    let(:other) { game.players.last }
    let(:step) { Engine::Game::G18EUS::Step::SpecialChoose.new(game, game.round) }
    let(:bank_lobbyist) do
      company = game.late_bloomer_companies.find { |c| c.sym == 'C4' }
      game.add_company_to_game(company) if company
      game.bank_lobbyist
    end

    before do
      game.stock_market.set_par(corp, game.stock_market.par_prices.find { |pp| pp.price == 70 })
      corp.ipoed = true
      game.share_pool.transfer_shares(corp.ipo_shares.first.to_bundle, president)
      corp.owner = president
    end

    def acquire
      bank_lobbyist.owner = corp
      corp.companies << bank_lobbyist
      game.company_bought(bank_lobbyist, corp)
    end

    def choose(choice)
      step.process_choose_ability(Engine::Action::ChooseAbility.new(bank_lobbyist, choice: choice))
    end

    def give_loans(player, count)
      count.times { player.take_loan! }
    end

    def pay_interest
      Engine::Game::G18EUS::Step::PayInterest.new(game, game.round).process_pay_interest(nil)
    end

    context 'when the president has no loans' do
      before { acquire }

      it 'offers to remove 4 loans' do
        expect(step.choices_ability(bank_lobbyist).keys).to eq(%w[remove_loans])
      end

      it 'removes 4 loans and closes' do
        game.loans_taken = 1

        choose('remove_loans')

        expect(game.loans_taken).to eq(5)
        expect(bank_lobbyist).to be_closed
      end

      it 'removes only the loans that are left' do
        game.loans_taken = game.total_loans - 2

        choose('remove_loans')

        expect(game.loans_taken).to eq(game.total_loans)
      end

      it 'rejects an unknown choice' do
        expect { choose('interest_discount') }.to raise_error(Engine::GameError)
      end

      it 'gives no discount' do
        give_loans(other, 2)

        expect(game.player_interest_owed(other)).to eq(game.interest_owed_for_loans(2))
      end

      it 'gives the discount if the president takes loans later' do
        give_loans(president, 2)
        full = game.interest_owed_for_loans(2)

        expect { pay_interest }.to change { president.cash }.by(-full / 2)
        expect(step.actions(bank_lobbyist)).to be_empty
      end
    end

    context 'when the president has loans' do
      before do
        give_loans(president, 2)
        acquire
      end

      it 'gives the discount automatically without a choice' do
        expect(game.player_interest_owed(president)).to eq(game.interest_owed_for_loans(2) / 2)
        expect(step.actions(bank_lobbyist)).to be_empty
        expect(bank_lobbyist).not_to be_closed
      end

      it 'halves the president\'s interest every OR' do
        give_loans(other, 2)
        full = game.interest_owed_for_loans(2)

        expect { pay_interest }.to change { president.cash }.by(-full / 2).and change { other.cash }.by(-full)
        expect { pay_interest }.to change { president.cash }.by(-full / 2)
      end

      it 'does not force a loan to cover the discounted interest' do
        president.spend(president.cash - (game.interest_owed_for_loans(2) * 3 / 4), game.bank)

        expect { pay_interest }.not_to(change { president.loans })
      end

      it 'gives the discount to a new president' do
        give_loans(other, 2)
        corp.owner = other

        expect(game.player_interest_owed(other)).to eq(game.interest_owed_for_loans(2) / 2)
        expect(game.player_interest_owed(president)).to eq(game.interest_owed_for_loans(2))
      end
    end
  end
end
