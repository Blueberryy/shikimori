class CollectionLinkSerializer < ActiveModel::Serializer
  attributes :linked_id, :linked_type, :group, :text, :name, :url

  def name
    scope.localized_name object.linked
  end

  def url
    scope.url_for object.linked
  end
end
