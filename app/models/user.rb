# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :submits

  def login=(login)
    puts 'set', login
    @login = login
  end

  def login
    puts 'get', @login || self.name || self.email
    @login || self.name || self.email
  end


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
          authentication_keys: [:email, :name]
  include DeviseTokenAuth::Concerns::User

  validates :name, presence: true, uniqueness: { case_sensitive: true }
  validates_format_of :name, with: /\A[a-zA-Z0-9_]{3,12}\z/, multiline: false
end
