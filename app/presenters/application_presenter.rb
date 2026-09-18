# frozen_string_literal: true

class ApplicationPresenter
  def initialize(entity)
    @entity = entity
  end

  private

  attr_reader :entity
end
