module ApplicationHelper
  def array_to_hash(values)
    hash = {}
    values.each do |k,v|
      hash[k] = v
    end
    return hash
  end
end
