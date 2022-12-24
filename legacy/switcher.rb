class Switcher
  def initialize(init, switch)
    @states = [init, switch]
    @state = init
  end
  def state
    @state
  end
  def switch
    @state = (@state == @states[0] ? @states[1] : @states[0])
  end
end
