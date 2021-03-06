# The User object
#
# @author Eric Fehr (ricofehr@nextdeploy.io, github: ricofehr)
class User < ActiveRecord::Base
  # An Heleer module contains IO functions
  include UsersHelper

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_projects, dependent: :destroy
  has_many :projects, through: :user_projects, inverse_of: :users
  has_many :own_projects, class_name: "Project", foreign_key: "owner_id", inverse_of: :owner
  has_many :vms, dependent: :destroy
  has_many :sshkeys, dependent: :destroy

  belongs_to :group

  # validates conditions
  validates :email, presence: true, length: {maximum: 255}, uniqueness: { case_sensitive: false }
  validates :group, presence: true

  # Some hooks before chnages on user object
  before_save :ensure_authentication_token

  before_create :init_user, :generate_sshkey_modem,
                :generate_authentication_token, :generate_openvpn_keys

  before_destroy :purge_user, prepend: true

  # Return current token and generates one before it if needed
  #
  # @return [String] token
  def ensure_authentication_token
    self.authentication_token ||= generate_authentication_token
  end

  # Reset current authentication_token
  #
  def reset_authentication_token!
    self.authentication_token = nil
    save
  end

  # Return gitlab username
  #
  # @return [String] gitlab username compliant
  def gitlab_user
    email.tr('@.','')
  end

  # Return group access_level
  #
  # @return [Number] group accesslevel
  def access_level
    group.access_level
  end

  # Return true if admin
  #
  # @return [Boolean] if admin
  def admin?
    group.admin?
  end

  # Return true if lead or admin
  #
  # @return [Boolean] if admin or lead
  def lead?
    group.lead?
  end

  # Return true if dev, lead or admin
  #
  # @return [Boolean] if admin or lead or dev
  def dev?
    group.dev?
  end

  # Return true if guest
  #
  # @return [Boolean] if guest and only guest
  def guest?
    group.access_level == 10
  end

  # Return true if project creation right
  #
  # @return [Boolean]
  def project_create?
    is_project_create
  end

  # Return true if user creation right
  #
  # @return [Boolean]
  def user_create?
    is_user_create
  end

  # Update the user to gitlab
  #
  def update_gitlabuser
    gitlabapi = Apiexternal::Gitlabapi.new

    begin
      gitlabapi.update_user(gitlab_id, email, password, gitlab_user, "#{firstname} #{lastname}")
      projects_g = gitlabapi.get_projects(gitlab_id)
      # remove user to project if needed
      projects_g.each do |project|
        unless projects.any? { |proj| proj.gitlab_id == project[:id] }
          gitlabapi.delete_user_to_project(project[:id], gitlab_id)
        end
      end

      projects.each do |project|
        unless projects_g.any? { |proj| proj[:id] == project.gitlab_id }
          gitlabapi.add_user_to_project(project.gitlab_id, gitlab_id, access_level)
        end
      end

    rescue Exceptions::NextDeployException => me
      me.log
    end
  end

  private

  # Create the user to gitlab, set gitlab_id attribute
  #
  def init_user
    gitlabapi = Apiexternal::Gitlabapi.new

    begin
      self.gitlab_id = gitlabapi.create_user(email, password, gitlab_user, "#{firstname} #{lastname}")
      projects.each do |project|
        gitlabapi.add_user_to_project(project.gitlab_id, gitlab_id, access_level)
      end
    rescue Exceptions::NextDeployException => me
      me.log
    end
  end

  # Purge current user from gitlab
  #
  def purge_user
    gitlabapi = Apiexternal::Gitlabapi.new

    begin
      gitlabapi.delete_user(gitlab_id)
    rescue Exceptions::NextDeployException => me
      me.log
    end

    delete_keyfiles
  end

  # Generate a token for Devise library
  #
  # @return [String] a token
  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.find_by(authentication_token: token)
    end
  end
end
