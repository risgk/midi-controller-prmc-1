class M5UnitDualButton
  def initialize(gpio_button_a:, gpio_button_b:)
    @button_blue = GPIO.new(gpio_button_a, GPIO::IN)
    @button_red = GPIO.new(gpio_button_b, GPIO::IN)
  end

  def get_button_blue_input
    @button_blue.read == 1 ? 0 : 1
  end

  def get_button_red_input
    @button_red.read == 1 ? 0 : 1
  end
end
