# frozen_string_literal: true

require_relative '../../../step/bankrupt'

module Engine
  module Game
    module G18EUS
      module Step
        class Bankrupt < Engine::Step::Bankrupt
          def active_entities
            return [@round.cash_crisis_entity] if @round.cash_crisis_entity

            super
          end

          def process_bankrupt(action)
            entity = action.entity
            player = entity.corporation? ? entity.owner : entity

            @log << "-- #{player.name} goes bankrupt --"

            # Close companies
            unless player.companies.empty?
              @log << "#{player.name}'s companies are removed from the game: #{player.companies.map(&:sym).join(', ')}"
              player.companies.each(&:close!)
            end

            # Repay loans
            if player.loans.positive?
              @log << "#{player.name}'s #{player.loans} loans are returned to the bank"
              @game.loans_taken -= player.loans
              player.loans = 0
            end

            loans_to_remove = [3, @game.remaining_loans].min
            if loans_to_remove.positive?
              @log << "#{loans_to_remove} loans are removed from the game"
              @game.loans_taken += loans_to_remove
            end

            # Close corporations; other shareholders sell to the pool at the current price
            @game.corporations.select { |corp| corp.owner == player }.each do |corp|
              share_price = corp.share_price.price

              corp.player_share_holders.each do |sh, percent|
                next if sh == player

                num_shares = percent / corp.share_percent
                next unless num_shares.positive?

                cash_total = share_price * num_shares
                @game.bank.spend(cash_total, sh)
                @log << "#{sh.name} receives #{@game.format_currency(cash_total)} for #{num_shares} " \
                        "#{corp.name} share#{'s' unless num_shares == 1} (#{@game.format_currency(share_price)} per share)"
              end

              @game.close_corporation(corp)
            end

            # Remaining shares go to the bank pool
            player.shares_by_corporation.to_a.each do |corp, shares|
              next if shares.empty?

              bundle = ShareBundle.new(shares)
              num_shares = bundle.num_shares
              @log << "#{player.name}'s #{num_shares} #{corp.name} share#{'s' unless num_shares == 1} " \
                      "#{num_shares == 1 ? 'goes' : 'go'} to the bank pool"
              @game.share_pool.transfer_shares(bundle, @game.share_pool, allow_president_change: false)
            end

            # Top train of the Next Available stack is returned to the box
            @game.depot.export! unless @game.depot.upcoming.empty?

            @game.declare_bankrupt(player)
            player.set_cash(0, @game.bank)

            @game.round.force_next_entity! if entity.corporation? && @round.skip_entity?(entity)
          end
        end
      end
    end
  end
end
