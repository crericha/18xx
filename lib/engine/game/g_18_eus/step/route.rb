# frozen_string_literal: true

require_relative '../../../step/route'
require_relative 'skip_bny'

module Engine
  module Game
    module G18EUS
      module Step
        class Route < Engine::Step::Route
          include SkipBny

          def actions(entity)
            actions = super.dup
            return actions if actions.empty?

            actions << 'choose' unless choices.empty?
            actions
          end

          def choice_name
            'Choose attachment and train'
          end

          def choices
            options = {}
            attachables = attachable_trains.uniq(&:name)
            attachments.reject { |attachment| attached_to(attachment) }.each do |attachment|
              attachables.each do |train|
                options[[train.id, attachment.id]] = "Attach #{attachment.name} to #{train.name} train"
              end
            end
            options
          end

          def process_choose(action)
            train = @game.train_by_id(action.choice[0])
            attachment = @game.train_by_id(action.choice[1])
            @log << "#{action.entity.id} chooses to attach #{attachment.name} to the #{train.name} train"
            attach(train, attachment)
          end

          def process_run_routes(action)
            super

            revenue = action.routes.sum(&:revenue)
            if (@game&.mail_contract&.owner == action.entity) && revenue.positive?
              mail_revenue = revenue * 0.2
              @log << "#{action.entity.name} receives #{@game.format_revenue_currency(mail_revenue)} " \
                      "from #{@game.mail_contract.name}."
              @game.bank.spend(mail_revenue, action.entity)
            end

            @game.rust(@game.plus_40) if attached_to(@game.plus_40)
            detach_attachments
          end

          def attachments
            @round.current_operator.trains.select { |t| @game.attachments.include?(t) }
          end

          def attached_to(attachment)
            @attached.find { |_, attachments| attachments.include?(attachment) }&.first
          end

          def attachable_trains
            @game.route_trains(@round.current_operator) - attachments
          end

          def attach(train, attachment)
            original = @attached.keys.find { |t| t.id == train.id } || train.dup
            @attached[original] << attachment

            if @game.train_extensions.include?(attachment)
              extension_distance = attachment.name[-1].to_i
              train.name = "#{train.name[0].to_i + extension_distance}#{train.name.slice(1..-1)}"
              if train.distance.is_a?(Hash)
                train.distance['pays'] += extension_distance
                train.distance['visits'] += extension_distance
              else
                train.distance += extension_distance
              end
            else
              train.name += attachment.name
            end
          end

          def detach_attachments
            @attached.keys.each do |original|
              train = @round.current_operator.trains.find { |t| t.id == original.id }
              train.name = original.name
              train.distance = original.distance
            end
          end

          def setup
            super
            @attached = Hash.new { |h, k| h[k] = [] }
          end
        end
      end
    end
  end
end
