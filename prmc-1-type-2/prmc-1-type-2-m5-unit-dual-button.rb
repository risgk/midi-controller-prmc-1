class M5UnitDualButton
  def initialize(gpio_blue_button:, gpio_red_button:)
    @button_blue = GPIO.new(gpio_blue_button, GPIO::IN)
    @button_red = GPIO.new(gpio_red_button, GPIO::IN)
  end

  def get_blue_button_input
    @button_blue.read == 1 ? 0 : 1
  end

  def get_red_button_input
    @button_red.read == 1 ? 0 : 1
  end
end
