require 'drb/drb'
require 'rinda/tuplespace'

module WizardFight
end

class WizardFight::TupleServer
  DEFAULT_URI = "druby://:12345".freeze

  def initialize(uri)
    @uri = uri || DEFAULT_URI
    @ts = Rinda::TupleSpace.new
  end

  def go!
    trap("INT") do
      $stderr.puts
      $stderr.puts("stopping server...")
      DRb.thread.kill
    end

    DRb.start_service(@uri, @ts)
    $stderr.puts("Listening on #{DRb.uri}")
    DRb.thread.join
  end
end
