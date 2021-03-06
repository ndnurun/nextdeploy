# This object stores all property about a git commit
#
# @author Eric Fehr (ricofehr@nextdeploy.io, github: ricofehr)
class Commit
  # Activemodel object without database table
  include ActiveModel::Serializers::JSON

  attr_reader :id, :commit_hash, :project_id, :branche_id, :short_id, :title,
              :author_name, :author_email, :message, :created_at

  # Constructor
  #
  # @param commit_hash [String] hash id of the commit
  # @param branche_id [String] projectid-branchname id of the branch
  # @param options [Hash{Symbol => String}] optional parameters (author, date, ...)
  def initialize(commit_hash, branche_id, options={})
    @id = "#{branche_id}-#{commit_hash}"
    @commit_hash = commit_hash
    @branche_id = branche_id
    @project_id = branche_id.split('-')[0]

    if options.empty?
      begin
        project = Project.find(@project_id)
        gitlabapi = Apiexternal::Gitlabapi.new
        commit = gitlabapi.get_commit(project.gitlab_id, commit_hash)

        options[:short_id] = commit.short_id
        options[:title] = commit.title
        options[:author_name] = commit.author_name
        options[:author_email] = commit.author_email
        options[:message] = commit.message
        options[:created_at] = commit.created_at
      rescue Exceptions::NextDeployException => me
        me.log
      end
    end

    @short_id = options[:short_id]
    @title = options[:title]
    @author_name = options[:author_name]
    @author_email = options[:author_email]
    @message = options[:message]
    @created_at = options[:created_at]
  end

  # Find function. Return a commit object from his id
  #
  # @param idstr [String] projectid-branchname-commithash string
  # @return [Commit]
  def self.find(idstr)
    tab = idstr.split('-')
    commit_hash = tab.pop
    branche_id = tab.join('-')

    Rails.cache.fetch("commits/#{branche_id}-#{commit_hash}", expires_in: 240.hours) do
      new(commit_hash, branche_id)
    end
  end

  # Return all commits for a branch
  #
  # @param branche_id [String]
  # @return [Array<Commit>]
  def self.all(branche_id)
    @gitlabapi = Apiexternal::Gitlabapi.new

    tab = branche_id.split('-')
    project_id = tab.shift
    branchname = tab.join('-')

    project = Project.find(project_id)

    begin
      commits = @gitlabapi.get_commits(project.gitlab_id, branchname)
    rescue Exceptions::NextDeployException => me
      me.log
    end

    commits.map do |commit|
      Rails.cache.fetch("commits/#{branche_id}-#{commit.id}", expires_in: 240.hours) do
        new(commit.id, branche_id, {short_id: commit.short_id,
                                    title: commit.title,
                                    author_name: commit.author_name,
                                    author_email: commit.author_email,
                                    message: commit.message,
                                    created_at: commit.created_at})
      end
    end
  end

  # Return the branch associated with the commit
  #
  # @return [Branche]
  def branche
    Rails.cache.fetch("commits/#{branche_id}-#{commit_hash}/branche", expires_in: 240.hours) do
      Branche.find(@branche_id)
    end
  end

  # Return the vms associated with the commit
  #
  # @return [Array<Vm>]
  def vms
    Vm.where(commit_id: @id)
  end
end
