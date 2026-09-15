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
end
