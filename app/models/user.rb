# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :submissions
  has_many :writer_problems, class_name: 'Problem', foreign_key: 'writer_user_id'
  has_many :tester_relations, foreign_key: :tester_user_id, dependent: :destroy
  has_many :contest_admins, dependent: :destroy
  has_many :tester_problems, through: :tester_relations, source: :user
  has_many :clarifications
  has_many :registrations

  def login=(login)
    @login = login
  end

  def login
    @login || self.name || self.email
  end

  def admin?
    self.role == 'admin'
  end

  def admin_for_contest?(contest_id)
    return true if self.admin?
    contest_id != nil && self.contest_admins.where(contest_id: contest_id).exists?
  end

  def writer?
    self.role == 'writer'
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
          authentication_keys: [:email, :name]
  include DeviseTokenAuth::Concerns::User

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { in: 3..12 }
  validates_format_of :name, with: /\A[a-zA-Z0-9_]{3,12}\z/, multiline: false
end
