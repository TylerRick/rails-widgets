class PathHash < HashWithIndifferentAccess
  # Adapted from clean_unwanted_keys (vendor/plugins/rails-widgets/lib/widgets/highlightable.rb)
  def initialize(hash)
    replace(hash)
    ignored_keys = [:only_path, :use_route]
    reject! {|key,value| ignored_keys.include?(key)}
  end
end
