# frozen_string_literal: true

class ServiceResult
  attr_reader :entity, :errors

  def self.success(entity:)
    new(success: true, entity: entity, errors: [])
  end

  def self.failure(entity:, errors:)
    new(success: false, entity: entity, errors: errors)
  end

  def initialize(success:, entity:, errors:)
    @success = success
    @entity = entity
    @errors = errors.map { |error| error.dup.freeze }.freeze
    freeze
  end
  private_class_method :new

  def success?
    @success
  end

  def failure?
    !success?
  end
end
