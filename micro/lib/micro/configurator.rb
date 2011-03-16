require 'highline/import'
require 'micro/network'
require 'micro/identity'
require 'micro/agent'
require 'micro/system'

module VCAP
  module Micro
    class Configurator

      def initialize
        @identity = Identity.new
      end

      def run
        # TODO: check highline's signal handling - might get in the way here
        %w{TERM INT}.each { |sig| trap(sig) { puts "Exiting Micro Cloud Configurator"; exit } }

        clear
        header
        #password # TODO OS auth/pwchange/pam auth
        identity

        network
        mounts

        @ip = VCAP::Micro::Network.local_ip
        install_identity
        install_micro
      end

      def header
        say("BETA - Welcome to VMware Micro Cloud Download - BETA\n\n")
        say("Please visit http://CloudFoundry.com register for a Micro Cloud token.\n\n")

        unless @identity.configured?
          exit unless agree("Micro Cloud Not Configured - Do you want to configure (y/n)?")
        else
          say("Current Configuration:")
          say("Identity: ")
          say("Networking (type)")

          exit unless agree("Re-configure Micro Cloud? (y/n)")
        end
      end

      def password
        # TODO: check if default has already been changed
        # TODO: ask for password if set 
        pass = ask("Configure Micro Cloud Password:  ") { |q| q.echo = "*" }
      end

      def identity
        say("\nConfigure Micro Cloud identity\n")
        choose do |menu|
          menu.choice(:token) { token }
          menu.choice(:dns_wildcard_name) { dns_wildcard_name }
        end

        # TODO: do this after we have network
        #unless @identity.admin?
        #  setup_admin
        #end
      end

      def token
        token = ask("Token: ")
        @identity.token(token)
      end

      def dns_wildcard_name
        name = ask("DNS wildcarded record: ")
        @identity.dns_wildcard_name(name)
      end

      def network
        say("\nConfigure Micro Cloud networking")
        choose do |menu|
          menu.choice(:dhcp) { dhcp_network }
          menu.choice(:manual) { manual_network }
        end

        proxy = ask("HTTP proxy: ") { |q| q.default = "none" }
      end

      def dhcp_network
        VCAP::Micro::Network.new.dhcp
      end

      def manual_network
        net = Hash.new
        say("Enter network configuration (address/netmask/gateway/DNS)")

        net['address'] = ask("Address: ")
        net['netmask'] = ask("Netmask: ")
        net['gateway'] = ask("Gateway: ")
        net['dns'] =     ask("DNS:     ")

        VCAP::Micro::Network.new.manual(net)
      end

      def mounts
        VCAP::Micro::System.mounts
      end

      def setup_admin
        admin = ask("Admin email: ")
        VCAP::Micro::Identity.setup_admin(admin)
      end

      def install_identity
        @identity.install(@ip)
      end

      def install_micro
        VCAP::Micro::Agent.apply
      end

      def start_micro
        #VCAP::Micro::Runner.start
      end

      def clear
        print "\e[H\e[2J"
      end
    end
  end

end

if __FILE__ == $0
  VCAP::Micro::Configurator.new.run
end