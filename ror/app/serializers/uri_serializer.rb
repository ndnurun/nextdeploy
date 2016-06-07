# This class format endpoint properties for json output
#
# @author Eric Fehr (ricofehr@nextdeploy.io, github: ricofehr)
class UriSerializer < ActiveModel::Serializer
  attributes :id, :absolute, :path, :envvars, :aliases, :ipfilter, :port

  has_one :vm, key: :vm
  has_one :framework, key: :framework
end