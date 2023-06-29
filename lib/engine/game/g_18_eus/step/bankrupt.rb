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
              @log << "#{player.name}'s #{player.loans.size} loans are returned to the bank"
              @game.loans_taken -= player.loans
              player.loans = 0
            end

            loans_to_remove = [3, @game.remaining_loans].min
            if loans_to_remove.positive?
              @log << "#{loans_to_remove} loans are removed from the game"
              @game.loans_taken += loans_to_remove
            end

            # Close corporations
            corps = @game.corporations.select { |corp| corp.owner == player }
            unless corps.empty?
              corps.each do |corp|
                share_price = corp.share_price.price
                share_holders = corp.player_share_holders.dup
                share_percent = 100 / (corp.total_shares.size + 1)

                share_holders.each do |sh, percent|
                  next if sh == entity

                  num_shares = percent / share_percent
                  next unless num_shares.positive?

                  cash_total = share_price * num_shares
                  @game.bank.spend(cash_total, sh)
                  @game.log << "#{sh.name} receives #{@game.format_currency(cash_total)} for #{num_shares}" \
                               " shares of #{corp.name} (#{@game.format_currency(share_price)} per share)"
                end

                @game.close_corporation(corp)
              end
            end

            @game.declare_bankrupt(player)
            player.cash = 0

            @game.round.force_next_entity! if entity.corporation? && @round.skip_entity?(entity)
          end
        end
      end
    end
  end
end
