module Tasks
  class Camp 
    def create_accounts
      1.upto(18) do |i|
        account_name = ("kyoprocamp2023west_team%03d" % i)
        email = ("camp23w_%03d@mofecoder.com" % i)
        password = Password.new.generate(18)
        puts account_name, password
        user = User.new(name: account_name, email: email, password: password, password_confirmation: password)
        user.save!(validation: false)

        Registration.create!(user_id: user.id, contest_id: 22)
      end
    end
  end

  class Password
    require 'securerandom'

    CHAR_LIST = 'abcdefghijklmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ123456789'.split('').freeze    # omit o,O,0
    SYMBOL_LIST = '._-=[]{}+#^!?'.split('').freeze
    # SYMBOL_LIST = '"#$%&\'()*+,-./:;<=>?[\]^_`{|}~'.split('').freeze
    SYMBOL_LIST_ESCAPED = SYMBOL_LIST.reduce('') { |r, s| r + '\\' + s }.freeze

    def initialize(symbol: false)
      @symbol = symbol
    end

    def generate(len = 8)
      raise 'too short' if len < 4
      raise 'too long'  if len > 32

      loop do
        result = (0..len - 1).reduce('') { |r, n| r + pick_one(len, n) }
        return result if check(result)
      end
    end

    private

    def pick_one(len, n)
      list = char_list(len, n)

      list[(SecureRandom.random_number(1.0) * list.size).floor]
    end

    def char_list(len, n)
      !@symbol || (n.zero? || n == len - 1) ? CHAR_LIST : CHAR_LIST + SYMBOL_LIST
    end

    def count_symbol(str)
      str.scan(Regexp.new('[%s]' % SYMBOL_LIST_ESCAPED)).size
    end

    def check(str)
      # omit successive chars
      return false if /(.)\1\1/ =~ str

      # confirm the str contains 1..2 symbols
      if @symbol
        return false if count_symbol(str).zero?
        return false if count_symbol(str) > 2
      end

      true
    end
  end

end
