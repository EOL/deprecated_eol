class MissingConcept
  attr_reader :id, :title_canonical_italicized
  def initialize(str = nil)
    @id = 0
    @title_canonical_italicized = str ? "<#{str}>" : "[MISSING]"
  end
end
