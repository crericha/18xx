# frozen_string_literal: true

require_relative '../../../step/bankrupt'

module Engine
  module Game
    module G18EUS
      module Step
        class Bankrupt < Engine::Step::Bankrupt
          def process_bankrupt(action)
            entity = action.entity
            player = entity.corporation? ? entity.owner : entity

            @log << "-- #{player.name} goes bankrupt --"

            # Close companies
            unless player.companies.empty?
              @log << "#{player.name}'s companies are removed from the game: #{player.companies.map(&:sym).join(', ')}"
              player.companies.each(&:close!)
            end

            # TODO: return loans here

            # Close corporations
            corps = @game.corporations.select { |corp| corp.owner == player }
            unless corps.empty?
              corps.each do |corp|
                share_price = corp.share_price.price
                share_holders = corp.player_share_holders.dup

                @game.close_corporation(corp)

                unless (share_holders = share_holders.reject { |sh, _| sh == player }).empty?
                  @game.log << "#{corp.name}'s share price was #{@game.format_currency(share_price)}"
                end

                share_holders.each do |sh, percent|
                  num_shares = percent / 10
                  cash_total = share_price * num_shares
                  @game.bank.spend(cash_total, sh)
                  @game.log << "#{sh.name} receives #{@game.format_currency(cash_total)} for #{num_shares} shares of #{corp.name}"
                end
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
