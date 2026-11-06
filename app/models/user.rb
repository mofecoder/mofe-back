# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :submissions
  has_many :writer_problems, class_name: 'Problem', foreign_key: 'writer_user_id'
  has_many :tester_relations, foreign_key: :tester_user_id, dependent: :destroy
  has_many :contest_admins, dependent: :destroy
  has_many :tester_problems, through: :tester_relations, source: :user
  has_many :clarifications
  has_many :registrations
  enum :role, { member: 'member', writer: 'writer', admin: 'admin' }

  def login=(login)
    @login = login
  end

  def login
    @login || self.name || self.email
  end

  def contest_admin?(contest)
    return true if self.admin?

    if contest.is_a?(Integer)
      contest = Contest.find(contest)
    end

    contest.present? && contest.admin?(self)
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

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { in: 3..20 }
  validates_format_of :name, with: /\A[a-zA-Z0-9_]{3,20}\z/, multiline: false
end
