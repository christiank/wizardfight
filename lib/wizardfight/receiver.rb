require 'drb/drb'
require 'rinda/tuplespace'

module WizardFight
end

class WizardFight::Receiver
  DEFAULT_URI = "druby://localhost:12345"

  def initialize(uri)
    @uri = uri || DEFAULT_URI
  end

  def go!
    DRb.start_service
    @ts = DRbObject.new_with_uri(@uri)
    @notifier = @ts.notify("write", {"action" => nil, "content" => nil})
    $stderr.puts("Connected to #{@uri}")

    trap("INT") do
      exit 0
    end

    loop do
      @notifier.each do |event, tuple|
        @action = tuple["action"]
        @content = tuple["content"]

        case @action
        when :chat
          $stdout.printf("%s: %s\n", @content[:from], @content[:body])
        when :enter
          message("%s has entered the game", @content[:from])
        when :exit
          message("%s has left the game", @content[:from])
        when :attack
          message("%s deals %d damage to %s!", @content[:from],
            @content[:damage], @content[:to])
        when :ready
          message("%s is ready!", @content[:from])
        when :begin
          message("Everybody is ready! BEGIN!!")
        else
          # complain
        end
      end
    end
  end

  private

  def message(fmt, *args)
    $stdout.printf("[#{fmt}]\n", *args)
  end
end
