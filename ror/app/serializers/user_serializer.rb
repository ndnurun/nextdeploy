# This class format user properties for json output
#
# @author Eric Fehr (ricofehr@nextdeploy.io, github: ricofehr)
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :authentication_token, :is_project_create, :is_user_create,
             :is_recv_vms, :company, :quotavm, :quotaprod, :nbpages, :layout, :firstname,
             :lastname, :created_at

  delegate :current_user, to: :scope

  has_many :vms, key: :vms
  has_many :sshkeys, key: :sshkeys
  has_one :group, key: :group
  has_many :projects, key: :projects
  has_many :own_projects, key: :own_projects

  # add shortname attribute
  def attributes
    data = super
    data[:shortname] = "#{object.firstname[0].upcase}. #{object.lastname}"
    data
  end

  # give auth_token only for current user
  def authentication_token
    object.authentication_token if !current_user || object.id == current_user.id
  end

  # avoid for no lead/admin users to see other users details
  def projects
    object.projects.select { |project| !current_user || project.users.include?(current_user) }
  end

  def own_projects
    if !current_user || current_user.admin? || object.id == current_user.id
      object.own_projects
    else
      []
    end
  end

  def vms
    object.vms.select do |vm|
      !current_user ||
      current_user.id == vm.user.id ||
      current_user.admin? ||
      (current_user.lead? && vm.project.users.include?(current_user)) ||
      (current_user.dev? && vm.project.users.include?(current_user) && vm.is_jenkins)
    end
  end

  def sshkeys
    object.sshkeys.select do |sshk|
      !current_user ||
      current_user.id == sshk.user.id ||
      current_user.lead?
    end
  end
end
