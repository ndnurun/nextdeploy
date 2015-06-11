# This class format user properties for json output
#
# @author Eric Fehr (eric.fehr@publicis-modem.fr, github: ricofehr)
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :authentication_token, :company, :quotavm, :created_at
  delegate :current_user, to: :scope

  has_many :vms, key: :vms
  has_many :projects, key: :projects
  has_many :sshkeys, key: :sshkeys
  has_one :group, key: :group

  # avoid for no lead/admin users to see other users details
  def projects
    object.projects.select { |p| p.users.include?(current_user) }
  end
end
