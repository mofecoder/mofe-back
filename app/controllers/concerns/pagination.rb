module Pagination
  # @param resources [ActiveRecord::Relation]
  def pagination(resources)
    {
      pagination: {
        current:  resources.current_page,
        previous: resources.prev_page,
        next:     resources.next_page,
        pages:    resources.total_pages,
        count:    resources.total_count
      }
    }
  end
end
