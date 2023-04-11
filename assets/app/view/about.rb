# frozen_string_literal: true

require 'user_manager'

module View
  class About < Snabberb::Component
    include UserManager

    needs :needs_consent, default: false
    needs :connection, store: true, default: nil

    def render
      @connection&.get('/version.json', '/assets') do |version|
        version_localtime = Time.at(version['version_epochtime'].to_i)
        link = node_to_s(h(:a, { attrs: { href: version['url'] } }, version['hash']))
        `document.getElementById('version').innerHTML = #{link}`
        `document.getElementById('version_localtime').innerHTML = #{version_localtime}`
      end

      message = <<~MESSAGE
        <h2>About 18eus.app</h2>

        <p>
        18eus.app is created and maintained by GMT Games. It is based on Toby Mao's open source 18xx.Games. The purpose of this website is to playtest GMT Games' 18xx titles.
        </p>

        <h2>Conduct Expectations</h2>

        <p>
        Be nice. Treat people with respect.
        </p>

        <h2>Privacy Policy</h2>

        <p>
        Upon your request and expression of consent, we collect the following data for the purpose of providing services to you. It is removed upon your request to terminate these services.
        </p>

        <p>
        <b>Email Addresses</b> are collected for login purposes.
        </p>

        <p>
        <b>IP Addresses</b> are collected when you use the site in order to prevent malicious behavior. These are not publicly available and not shared to any 3rd party.
        </p>

        <p>
        <b>Game Data</b> is collected when you play a game and is needed for the game to function. Game Data is publicly available through the website interface and API. In-game messages are only visible to the players in the game (whether via the website or the API).
        </p>

        <p>
        <b>Local Storage</b> is used to store local data like hot seat games and master mode. This can only be accessed by your device.
        </p>
      MESSAGE

      children = [h(:div, props: { innerHTML: message })]

      if @needs_consent
        @confirmation = h(:input, attrs: { placeholder: 'Type DELETE to confirm' })

        children << h(:div, [
          h(:h2, 'In order to continue using your account, you must give consent'),
          h(:button, { on: { click: -> { consent } } }, 'I agree to the privacy policy'),
          h(:button, { on: { click: -> { delete } } }, 'Delete my account and all data'),
          @confirmation,
        ])
      end

      h('div#about', children)
    end

    def consent
      edit_user(consent: true)
      store(:app_route, '/')
    end

    def delete
      return store(:flash_opts, 'Confirmation not correct') if Native(@confirmation).elm.value != 'DELETE'

      delete_user
    end
  end
end
