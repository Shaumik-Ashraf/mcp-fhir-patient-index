module Util
  QWERTY = "qwertyuiop[]\\nasdfghjkl;'\nzxcvbnm,./".upcase.split("\n")

  # @param [String] str
  # @option [Float] randomness - from 0 to 1
  # @option [Random] random - seeded generator
  # @return [String]
  def typo(str, randomness: 0.2, random: nil)
    random ||= Random.new
    ret = ""
    str.each_char do |char|
      if random.rand < randomness
        if random.rand <= 0.33 # 33% chance of replacement
          ret << adjacent_character(char, random:)
        elsif random.rand <= 0.66 # 33% chance of insertion
          if random.rand <= 0.5
            ret << adjacent_character(char, random:)
            ret << char
          else
            ret << char
            ret << adjacent_character(char, random:)
          end
        else # deletion
          next
        end
      else
        ret << char
      end
    end

    ret
  end

  private

  def adjacent_character(char, random: nil)
    char.upcase!
    keyboard_row = QWERTY.find_index { |keys| keys.include? char }
    if keyboard_row.nil? # str has non-qwerty character like ñ, use any QWERTY character
      random_case QWERTY.sample(random:).chars.sample(random:)
    else
      keyboard_col = QWERTY[keyboard_row].index(char)

      keyboard_row + [ -1, 0, 1 ].sample(random:)
      keyboard_col + [ -1, 0, 1 ].sample(random:)

      keyboard_row = fit(keyboard_row, 0, QWERTY.length-1)
      keyboard_col = fit(keyboard_col, 0, QWERTY[keyboard_row].length-1)

      random_case QWERTY[keyboard_row][keyboard_col]
    end
  end

  def random_case(char, random: nil)
    random ||= Random.new
    if random.rand <= 0.5
      char.upcase
    else
      char.downcase
    end
  end

  def fit(int, min, max)
    int = min if int < min
    int % max
  end
end
