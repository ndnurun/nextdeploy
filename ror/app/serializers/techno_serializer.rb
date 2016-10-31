# This class format techno properties for json output
#
# @author Eric Fehr (ricofehr@nextdeploy.io, github: ricofehr)
class TechnoSerializer < ActiveModel::Serializer
  attributes :id, :name, :dockercompose, :playbook
  delegate :current_user, to: :scope

  has_one :technotype, key: :technotype
  has_many :projects, key: :projects

  # dont display projects if user is not allowed for
  def projects
    if current_user.admin?
      object.projects
    else
      object.projects.select { |project| project.users.include?(current_user) }
    end
  end
end
