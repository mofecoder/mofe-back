# frozen_string_literal: true

class User < ActiveRecord::Base
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
          authentication_keys: [:email]
  include DeviseTokenAuth::Concerns::User

  validates :name, presence: true, uniqueness: { case_sensitive: true }
  validates_format_of :name, with: /\A[a-zA-Z0-9_]{3,12}\z/, multiline: false

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    p 'find called'
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", {value: login.strip.downcase}]).first
  end
end
