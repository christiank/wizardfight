require 'drb/drb'
require 'rinda/tuplespace'

module WizardFight
end

class WizardFight::Pusher
  TIMEOUT = 30
  VALID_ACTIONS = [:chat, :enter, :exit, :ready, :begin, :attack].freeze
  DEFAULT_URI = "druby://localhost:12345".freeze
  PROMPT = ">>"

  def initialize(uri, name)
    @uri = uri || DEFAULT_URI
    @name = name
  end

  def go!
    DRb.start_service
    @ts = DRbObject.new_with_uri(@uri)
    current_names = all_players.map { |x| x["player"] }

    if current_names.include?(@name)
      warn_local("There already is a player named #{@name}! Exiting.")
      exit 1
    end

    $stderr.puts("Connected to #{@uri}")
    commit_player(:hp => 50)

    at_exit do  
      broadcast(new_action(:exit, :from => @name))
      remove_player
    end

    trap("INT") { exit 0 }
    main_loop
    exit 0
  end

  private

  # Adds this player to the tuple space.
  def commit_player(opts)
    tuple = {
      "player" => @name,
      "info" => {
        :hp_cur => opts[:hp],
        :hp_max => opts[:hp],
      }
    }
    @ts.write(tuple)
    broadcast(new_action(:enter, :from => @name))
  end

  # Removes this player from the tuplespace.
  def remove_player
    @ts.take({"player" => @name, "info" => Hash})
    @ts.take({"ready" => true, "from" => @name})
  end

  def all_players
    return @ts.read_all({"player" => String, "info" => Hash})
  end

  def me
    return @ts.read({"player" => @name, "info" => Hash})
  end
  
  def main_loop
    catch(:exiting) do
      loop do
        $stdout.print(PROMPT, " ")
        @line = $stdin.gets.chomp
        next if @line.empty?
        @line =~ /\A\// ? handle_slash_command : handle_chat
      end
    end
  end

  def handle_slash_command
    case @line
    when "/attack"
      attack_cmd
    when "/quit", "/exit", "/leave"
      quit_cmd
    when "/players"
      warn_local(all_players.map { |x| x["player"] }.inspect)
    when "/ready"
      ready_cmd
    when "/me"
      warn_local(me.inspect)
    else
      warn_local("not a slash-command: #{@line.inspect}")
    end
  end

  def warn_local(msg)
    $stderr.puts("!! #{msg}")
  end

  def handle_chat
    act = new_action(:chat, :from => @name, :body => @line)
    broadcast(act)
  end

  def ready_cmd
    if who_is_ready.include?(@name)
      warn_local("You already said you were ready.")
      return
    end

    i_am_ready!

    if (who_is_ready.length >= 2) and
      (who_is_ready.length == all_players.length) then
        broadcast(new_action(:begin))
        @ts.write(
          {"turn" => all_players[rand(all_players.length)]["player"]})
    end
  end

  def who_is_ready
    return @ts.read_all({"ready" => true, "from" => String}).
      map { |x| x["from"] }
  end

  def i_am_ready!
    @ts.write({"ready" => true, "from" => @name})
    broadcast(new_action(:ready, :from => @name))
  end

  def switch!
    players = all_players.map { |x| x["player"] }
    cur_player = @ts.take({"turn" => String}).first
    players.delete(cur_player["turn"])
    other = players.first
    @ts.write({"turn" => other})
  end

  def attack_cmd
    players = all_players

    who_is_ready = @ts.read_all({"ready" => true, "from" => String})
    if who_is_ready.length < players.length
      warn_local("Everybody must be ready first!")
      return
    end

    if players.length < 2
      warn_local("Someone else needs to join the game!")
      return
    end

=begin
    if not @ts.read_all({"turn" => @name}).any?
      warn_local("It is not your turn!")
      return
    end
=end

    other_name = players.
      map { |x| x["player"] }.
      reject { |x| x == @name }.
      first

    other_player = @ts.take({"player" => other_name, "info" => Hash})
    damage = rand(7) + 1
    other_player["info"][:hp_cur] -= damage
    @ts.write(other_player)

    act = new_action(:attack,
      :from => @name, :to => other_name, :damage => damage)
    broadcast(act)
    #switch!
  end

  def quit_cmd
    throw(:exiting)
  end

  def new_action(action, content={})
    raise ArgumentError if VALID_ACTIONS.none? { |a| a == action }
    return {"action" => action, "content" => content}
  end

  def broadcast(action_h)
    @ts.write(action_h, TIMEOUT)
  end
end # class WizardFight::Pusher
