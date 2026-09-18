# frozen_string_literal: true

class ApplicationService
  def self.call(...)
    new.call(...)
  end

  private

  def validation_failure(entity)
    errors = entity.errors.map do |error|
      {
        attribute: error.attribute,
        code: error.type.is_a?(Symbol) ? error.type : :invalid,
        message: error.full_message
      }
    end
    ServiceResult.failure(entity: entity, errors: errors)
  end
end
