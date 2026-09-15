# frozen_string_literal: true

require 'spec_helper'

describe Engine::Game::G18EUS::Game do
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

      expect(game.player_status_str(player)).to eq('Status: neutral')
    end

    it 'shows +loan / -bank after the player takes a loan' do
      reach_stock_round(game)
      game.process_action(Engine::Action::TakeLoan.new(player, loan: nil))

      expect(game.player_status_str(player)).to eq('Status: +loan / -bank')
    end

    it 'shows +bank / -loan after the player repays a loan' do
      reach_stock_round(game)
      player.take_loan!
      game.loans_taken += 1
      game.process_action(Engine::Action::PayoffLoan.new(player, loan: nil))

      expect(game.player_status_str(player)).to eq('Status: +bank / -loan')
    end

    it 'shows +bank / -loan after the player buys a BNY share' do
      reach_stock_round(game)
      bundle = game.bny.treasury_shares.first.to_bundle
      game.process_action(Engine::Action::BuyShares.new(player, shares: bundle.shares))

      expect(game.player_status_str(player)).to eq('Status: +bank / -loan')
    end

    it 'shows +loan / -bank after the player sells a BNY share' do
      reach_stock_round(game)
      game.share_pool.transfer_shares(game.bny.treasury_shares.first.to_bundle, player)
      bundle = player.shares_of(game.bny).first.to_bundle
      game.process_action(Engine::Action::SellShares.new(player, shares: bundle.shares))

      expect(game.player_status_str(player)).to eq('Status: +loan / -bank')
    end

    it 'only reflects the acting player' do
      reach_stock_round(game)
      other = game.players.find { |p| p != player }
      game.process_action(Engine::Action::TakeLoan.new(player, loan: nil))

      expect(game.player_status_str(other)).to eq('Status: neutral')
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
end
